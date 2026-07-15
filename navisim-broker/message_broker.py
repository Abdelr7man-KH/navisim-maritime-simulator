"""
Maritime Simulation Broker - Monitor & Control GUI
====================================================
Wraps the OSC/UDP vessel-simulation broker (Unreal <-> pymaneuvering <-> Qt
instructor station <-> Radar) with a Tkinter tabbed dashboard:

    1. Settings        - edit IP/Port for every endpoint (Visuals, Weather,
                          Water, Broker inbound, Instructor, UI commands,
                          Radar, and ECDIS wired in advance)
    2. Visuals Logs     - live physics state, throttled to one snapshot / 2s,
                          numeric values color-highlighted for readability
    3. Instructor Logs  - commands RECEIVED from Qt (green) and the resulting
                          messages SENT out (blue). Only command-triggered
                          events are logged (the continuous 50Hz state stream
                          is NOT logged).
    4. Radar Logs       - live blip/land forwarding to the radar app, with
                          the target IP:port shown on every line
    5. ECDIS Logs       - placeholder, functionality TBD

Run:  python broker_gui.py
Requires: python-osc, pymaneuvering
"""

import socket
import json
import math
import time
import os
import threading
import queue
import tkinter as tk
from tkinter import ttk, messagebox

from pythonosc import udp_client, osc_server, dispatcher
from pythonosc.osc_message_builder import OscMessageBuilder
from pymaneuvering import Vessel, VTYPE


# =========================================================
# 1. CONFIGURATION (mutable - edited live from the Settings tab)
# =========================================================
class Config:
    def __init__(self):
        # Visuals (Unreal)
        self.UE_IP = "192.168.1.14"
        self.UE_OUT_PORT = 8000
        self.UE_WEATHER_PORT = 6767
        self.UE_WATER_PORT = 5005

        # Broker inbound (from Unreal, via OSC)
        self.BROKER_IN_PORT = 5555

        # Instructor (Qt station)
        self.INSTRUCTOR_IP = "127.0.0.1"
        self.INSTRUCTOR_PORT = 9000

        # Qt UI command channel (RECORD_START, REPLAY_START, WEATHER, ...)
        self.UI_CMD_PORT = 5556

        # Radar
        self.RADAR_IP = "127.0.0.1"
        self.RADAR_PORT = 5006

        # ECDIS - wired in advance, not yet used
        self.ECDIS_IP = "127.0.0.1"
        self.ECDIS_PORT = 7100


CFG = Config()

# Fixed mapping of weather command keys -> OSC addresses on the Unreal side
COMMAND_MAP = {
    "rain": "/weather/rain/intensity",       # 0 to 10000
    "storm": "/weather/storm/intensity",     # 0.0 to 1.0
    "lightning": "/weather/storm/lightning",  # 0.0 to 1.0
    "fog_density": "/weather/fog/density",   # 0.0 to 0.05
    "fog_height": "/weather/fog/height",     # 0.0 to 100.0
    "time": "/weather/sky/time",             # 0.0 to 24.0 (Solar Time)
    "rotation": "/weather/sky/rotation",     # 0.0 to 360.0 (North Offset)
}

# =========================================================
# 2. THREAD-SAFE LOG QUEUES
# =========================================================
visuals_queue = queue.Queue()      # holds list[(text, tag)] -> one full line
instructor_queue = queue.Queue()   # holds (text, tag) -> one full line
radar_queue = queue.Queue()        # holds (text, tag) -> one full line


def log_visuals(segments):
    """segments: list of (text, tag) tuples making up one line."""
    visuals_queue.put(segments)


def log_instructor(text, tag="normal"):
    instructor_queue.put((text, tag))


def log_radar(text, tag="normal"):
    radar_queue.put((text, tag))


# =========================================================
# 3. PHYSICS / BROKER STATE
# =========================================================
vessel = Vessel(new_from=VTYPE.KVLCC2_L64)
pos = [0.0, 0.0]
psi = 0.0
uvr = [0.0, 0.0, 0.0]

system_mode = "LIVE"           # LIVE | RECORDING | REPLAYING
SNAPSHOT_INTERVAL = 0.5
record_timer = 0.0
recorded_timeline = []
replay_time = 0.0
is_paused = False

VISUALS_LOG_INTERVAL = 2.0     # seconds - throttled logging as requested
_last_visuals_log_time = 0.0

ue_client = None
weather_client = None
instructor_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
radar_json_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def rebuild_clients():
    """Rebuild all UDP client objects that depend on CFG (call after any
    IP/Port change to Visuals/Weather settings)."""
    global ue_client, weather_client
    ue_client = udp_client.SimpleUDPClient(CFG.UE_IP, CFG.UE_OUT_PORT)
    weather_client = udp_client.UDPClient(CFG.UE_IP, CFG.UE_WEATHER_PORT)


rebuild_clients()


def send_strict_float(address, value):
    """Packages a number as a strict 32-bit float and sends it to Unreal."""
    builder = OscMessageBuilder(address=address)
    builder.add_arg(float(value), arg_type="f")  # 'f' forces 32-bit
    weather_client.send(builder.build())


def log_visuals_snapshot(dT):
    """Formats the two requested log lines with numbers tagged for color."""
    log_visuals([
        ("\u23f1\ufe0f Received dT: ", "label"), (f"{dT:.4f}", "num"),
        (" | \U0001f6a2 Speed Surge (u): ", "label"), (f"{uvr[0]:.2f}", "num"),
        (" m/s", "label"),
    ])
    log_visuals([
        ("Broker: Updated State - X:", "label"), (f"{pos[0]:.2f}", "num"),
        (" Y:", "label"), (f"{pos[1]:.2f}", "num"),
        (" H:", "label"), (f"{math.degrees(psi):.1f}", "num"),
    ])


def handle_visuals_input(address, *args):
    global pos, psi, uvr, system_mode, record_timer, recorded_timeline
    global replay_time, _last_visuals_log_time

    try:
        dT, nps, delta = args
    except ValueError:
        return

    # ---------------- LIVE / RECORDING ----------------
    if (system_mode in ("LIVE", "RECORDING")) and (not is_paused):
        new_uvr, new_eta = vessel.pstep(
            X=uvr, pos=pos, psi=psi,
            dT=dT, nps=nps,
            delta=delta * (math.pi / 180.0)
        )
        uvr = new_uvr
        pos = new_eta[0:2]
        psi = new_eta[2]

        if system_mode == "RECORDING":
            record_timer += dT
            if record_timer >= SNAPSHOT_INTERVAL:
                recorded_timeline.append({
                    "x": pos[0], "y": pos[1], "psi": psi,
                    "surge": uvr[0], "sway": uvr[1], "yaw_rate": uvr[2],
                    "rudder": delta, "nps": nps
                })
                record_timer = 0.0

    # ---------------- REPLAYING ----------------
    elif (system_mode == "REPLAYING") and (not is_paused):
        if len(recorded_timeline) < 2:
            log_instructor("\u26a0\ufe0f Not enough data to replay -> LIVE", "warn")
            system_mode = "LIVE"
            return

        replay_time += dT
        index_a = int(replay_time // SNAPSHOT_INTERVAL)
        index_b = index_a + 1

        if index_b >= len(recorded_timeline):
            log_instructor("\u2705 Replay finished -> LIVE", "warn")
            system_mode = "LIVE"
            return

        snap_a = recorded_timeline[index_a]
        snap_b = recorded_timeline[index_b]
        t = (replay_time % SNAPSHOT_INTERVAL) / SNAPSHOT_INTERVAL

        pos[0] = snap_a["x"] + (snap_b["x"] - snap_a["x"]) * t
        pos[1] = snap_a["y"] + (snap_b["y"] - snap_a["y"]) * t

        diff_psi = ((snap_b["psi"] - snap_a["psi"] + math.pi) % (2 * math.pi)) - math.pi
        psi = snap_a["psi"] + (diff_psi * t)

        uvr[0] = snap_a["surge"]
        delta = snap_a["rudder"]
        nps = snap_a["nps"]

    # ---------------- BROADCAST ----------------
    ue_client.send_message("/vessel/state", [pos[0], pos[1], math.degrees(psi)])

    instructor_payload = {
        "x": pos[0], "y": pos[1], "heading": math.degrees(psi),
        "surge": uvr[0], "sway": uvr[1], "yaw_rate": uvr[2],
        "rudder": delta, "nps": nps,
        "sent_time": int(time.time() * 1000),
        "mode": system_mode
    }
    instructor_sock.sendto(json.dumps(instructor_payload).encode(),
                            (CFG.INSTRUCTOR_IP, CFG.INSTRUCTOR_PORT))

    # ---------------- THROTTLED VISUALS LOG (every 2s) ----------------
    now = time.time()
    if now - _last_visuals_log_time >= VISUALS_LOG_INTERVAL:
        _last_visuals_log_time = now
        log_visuals_snapshot(dT)


# =========================================================
# 4. RADAR FORWARDING (Unreal OSC -> JSON over raw UDP)
# =========================================================
def forward_radar_blip_json(address, *args):
    """Converts Unreal OSC blips to JSON and sends over raw UDP to Radar."""
    if len(args) >= 3:
        payload = {"type": "blip", "name": args[0], "x": args[1], "y": args[2]}
        json_data = json.dumps(payload).encode("utf-8")
        radar_json_sock.sendto(json_data, (CFG.RADAR_IP, CFG.RADAR_PORT))
        log_radar(
            f"\U0001f6f0\ufe0f BLIP -> {CFG.RADAR_IP}:{CFG.RADAR_PORT}   "
            f"name={args[0]}  x={args[1]:.1f}  y={args[2]:.1f}",
            "blip"
        )


def forward_radar_land_json(address, *args):
    """Converts Unreal OSC land coordinate sweeps to JSON and sends over raw UDP."""
    payload = {"type": "land", "points": list(args)}
    json_data = json.dumps(payload).encode("utf-8")
    radar_json_sock.sendto(json_data, (CFG.RADAR_IP, CFG.RADAR_PORT))
    log_radar(
        f"\U0001f5fa\ufe0f LAND -> {CFG.RADAR_IP}:{CFG.RADAR_PORT}   "
        f"{len(args)} coords ({len(args) // 2} points)",
        "land"
    )


# =========================================================
# 5. RECORDING SAVE/LOAD HELPERS
# =========================================================
def save_recording(filename, timeline_data):
    if not filename:
        filename = "unnamed_scenario.json"
    if not filename.endswith(".json"):
        filename += ".json"
    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(timeline_data, f, indent=4)
        log_instructor(f"\U0001f4be Saved scenario -> {filename}", "sent")
    except Exception as e:
        log_instructor(f"\u274c Error saving scenario: {e}", "warn")


def load_scenario(filename):
    global recorded_timeline
    if not filename:
        log_instructor("\u274c No filename provided to load.", "warn")
        return False
    if not filename.endswith(".json"):
        filename += ".json"
    if not os.path.exists(filename):
        log_instructor(f"\u274c File '{filename}' not found.", "warn")
        return False
    try:
        with open(filename, "r", encoding="utf-8") as f:
            recorded_timeline = json.load(f)
        log_instructor(f"\U0001f4c2 Loaded '{filename}' ({len(recorded_timeline)} snapshots)", "sent")
        return True
    except Exception as e:
        log_instructor(f"\u274c Error loading scenario: {e}", "warn")
        return False


# =========================================================
# 6. BROKER SERVICE (owns the sockets/threads, restartable)
# =========================================================
class BrokerService:
    def __init__(self, cfg):
        self.cfg = cfg
        self.osc_srv = None
        self.osc_thread = None
        self.cmd_sock = None
        self.cmd_thread = None
        self.running = False

    def start(self):
        if self.running:
            return
        rebuild_clients()

        dispatch = dispatcher.Dispatcher()
        dispatch.map("/vessel/input", handle_visuals_input)
        dispatch.map("/radar/blip", forward_radar_blip_json)
        dispatch.map("/radar/land", forward_radar_land_json)
        self.osc_srv = osc_server.ThreadingOSCUDPServer(
            ("0.0.0.0", self.cfg.BROKER_IN_PORT), dispatch
        )
        self.osc_thread = threading.Thread(target=self.osc_srv.serve_forever, daemon=True)
        self.osc_thread.start()

        self.cmd_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.cmd_sock.bind(("0.0.0.0", self.cfg.UI_CMD_PORT))
        self.running = True
        self.cmd_thread = threading.Thread(target=self._cmd_loop, daemon=True)
        self.cmd_thread.start()

        log_instructor(
            f"\U0001f7e2 Broker started  (OSC in :{self.cfg.BROKER_IN_PORT}  |  "
            f"UI cmd :{self.cfg.UI_CMD_PORT})", "sent"
        )
        log_radar(
            f"\U0001f7e2 Radar forwarding active -> {self.cfg.RADAR_IP}:{self.cfg.RADAR_PORT}",
            "info"
        )

    def stop(self):
        if not self.running:
            return
        self.running = False
        try:
            if self.osc_srv:
                self.osc_srv.shutdown()
                self.osc_srv.server_close()
        except Exception:
            pass
        try:
            if self.cmd_sock:
                self.cmd_sock.close()
        except Exception:
            pass
        log_instructor("\U0001f534 Broker stopped", "warn")
        log_radar("\U0001f534 Radar forwarding stopped", "warn")

    def restart(self):
        self.stop()
        time.sleep(0.2)
        self.start()

    def _cmd_loop(self):
        global system_mode, recorded_timeline, record_timer, replay_time, is_paused

        while self.running:
            try:
                data, addr = self.cmd_sock.recvfrom(1024)
            except OSError:
                break  # socket closed -> stop() was called

            raw_string = data.decode("utf-8").strip()
            try:
                json_data = json.loads(raw_string)
                command = json_data.get("command", "")
                filename = json_data.get("filename", "")
                cmd_data = json_data.get("data", {})
            except json.JSONDecodeError:
                log_instructor(f"\u26a0\ufe0f Invalid JSON received: {raw_string}", "warn")
                continue

            # Command RECEIVED from Qt -> green
            suffix = f" ({filename})" if filename else ""
            log_instructor(f"\u2b07\ufe0f RECEIVED: {command}{suffix}", "received")

            if command == "ENGINE_FAILURE":
                ue_client.send_message("/instructor/fault", 1.0)
                log_instructor("\u2b06\ufe0f SENT: engine fault -> ON", "sent")

            elif command == "ENGINE_START":
                ue_client.send_message("/instructor/fault", 0)
                log_instructor("\u2b06\ufe0f SENT: engine fault -> OFF", "sent")

            elif command == "PAUSE":
                is_paused = True
                ue_client.send_message("/system/mode", [1.0])
                log_instructor("\u2b06\ufe0f SENT: system mode -> PAUSED", "sent")

            elif command == "START":
                is_paused = False
                ue_client.send_message("/system/mode", [0.0])
                log_instructor("\u2b06\ufe0f SENT: system mode -> RUNNING", "sent")

            elif command == "WEATHER":
                for key, value in cmd_data.items():
                    target_address = COMMAND_MAP.get(key)
                    if target_address:
                        send_strict_float(target_address, value)
                        log_instructor(f"\u2b06\ufe0f SENT: {target_address} = {value}", "sent")
                    else:
                        log_instructor(f"\u26a0\ufe0f Unknown weather key: {key}", "warn")

            elif command == "WATER":
                water_json = json.dumps(cmd_data).encode("utf-8")
                instructor_sock.sendto(water_json, (CFG.UE_IP, CFG.UE_WATER_PORT))
                log_instructor(
                    f"\u2b06\ufe0f SENT: water packet -> {CFG.UE_IP}:{CFG.UE_WATER_PORT}", "sent"
                )

            elif command == "RECORD_START":
                recorded_timeline = []
                record_timer = 0.0
                system_mode = "RECORDING"
                log_instructor("\u2b06\ufe0f SENT: mode -> RECORDING", "sent")

            elif command == "RECORD_STOP":
                system_mode = "LIVE"
                save_recording(filename, recorded_timeline)
                log_instructor(
                    f"\u2b06\ufe0f SENT: mode -> LIVE ({len(recorded_timeline)} snapshots)", "sent"
                )

            elif command == "REPLAY_START":
                if len(recorded_timeline) > 0:
                    replay_time = 0.0
                    system_mode = "REPLAYING"
                    log_instructor("\u2b06\ufe0f SENT: mode -> REPLAYING", "sent")
                else:
                    log_instructor("\u26a0\ufe0f Cannot start replay: no data recorded", "warn")

            elif command == "LOAD_SCENARIO":
                load_scenario(filename)

            else:
                system_mode = "LIVE"
                log_instructor("\u2b06\ufe0f SENT: mode -> LIVE (unknown command)", "sent")


broker = BrokerService(CFG)


# =========================================================
# 7. GUI
# =========================================================
DARK_BG = "#1e1e1e"
PANEL_BG = "#252526"
FG_MAIN = "#d4d4d4"


class SettingsTab(ttk.Frame):
    def __init__(self, master, app):
        super().__init__(master, padding=16)
        self.app = app
        self.vars = {}
        self._build()

    def _section(self, parent, title, fields, row):
        frame = ttk.LabelFrame(parent, text=title, padding=10)
        frame.grid(row=row, column=0, sticky="ew", pady=8, padx=4)
        frame.columnconfigure(1, weight=1)
        for i, (label, attr, is_port) in enumerate(fields):
            ttk.Label(frame, text=label).grid(row=i, column=0, sticky="w", padx=4, pady=4)
            var = tk.StringVar(value=str(getattr(CFG, attr)))
            entry = ttk.Entry(frame, textvariable=var, width=22)
            entry.grid(row=i, column=1, sticky="ew", padx=4, pady=4)
            self.vars[attr] = (var, is_port)
        return frame

    def _build(self):
        self.columnconfigure(0, weight=1)

        self._section(self, "Visuals (Unreal Engine)", [
            ("IP Address", "UE_IP", False),
            ("Out Port", "UE_OUT_PORT", True),
            ("Weather Port", "UE_WEATHER_PORT", True),
            ("Water Port", "UE_WATER_PORT", True),
        ], row=0)

        self._section(self, "Broker Inbound (from Unreal, OSC)", [
            ("Listen Port", "BROKER_IN_PORT", True),
        ], row=1)

        self._section(self, "Instructor Station (Qt)", [
            ("IP Address", "INSTRUCTOR_IP", False),
            ("Port", "INSTRUCTOR_PORT", True),
        ], row=2)

        self._section(self, "Qt UI Command Channel", [
            ("Listen Port", "UI_CMD_PORT", True),
        ], row=3)

        self._section(self, "Radar", [
            ("IP Address", "RADAR_IP", False),
            ("Port", "RADAR_PORT", True),
        ], row=4)

        self._section(self, "ECDIS (reserved for future use)", [
            ("IP Address", "ECDIS_IP", False),
            ("Port", "ECDIS_PORT", True),
        ], row=5)

        btn_row = ttk.Frame(self)
        btn_row.grid(row=6, column=0, sticky="ew", pady=(12, 0))

        self.status_lbl = ttk.Label(btn_row, text="Broker: stopped", foreground="#cc4444")
        self.status_lbl.pack(side="left", padx=4)

        ttk.Button(btn_row, text="Apply Settings & Restart",
                   command=self.apply_settings).pack(side="right", padx=4)
        ttk.Button(btn_row, text="Stop Broker",
                   command=self.stop_broker).pack(side="right", padx=4)
        ttk.Button(btn_row, text="Start Broker",
                   command=self.start_broker).pack(side="right", padx=4)

    def _read_into_cfg(self):
        for attr, (var, is_port) in self.vars.items():
            value = var.get().strip()
            if is_port:
                try:
                    value = int(value)
                except ValueError:
                    messagebox.showerror("Invalid value", f"{attr} must be an integer port.")
                    return False
            setattr(CFG, attr, value)
        return True

    def apply_settings(self):
        if not self._read_into_cfg():
            return
        was_running = broker.running
        try:
            if was_running:
                broker.restart()
            else:
                rebuild_clients()
            self.set_status(broker.running)
            self.app.radar_tab.refresh_target()
            messagebox.showinfo("Settings applied", "Configuration updated successfully.")
        except OSError as e:
            messagebox.showerror("Failed to bind", f"Could not apply new ports:\n{e}")

    def start_broker(self):
        if not self._read_into_cfg():
            return
        try:
            broker.start()
            self.set_status(True)
            self.app.radar_tab.refresh_target()
        except OSError as e:
            messagebox.showerror("Failed to start", str(e))

    def stop_broker(self):
        broker.stop()
        self.set_status(False)

    def set_status(self, running):
        if running:
            self.status_lbl.configure(text="Broker: running", foreground="#33cc66")
        else:
            self.status_lbl.configure(text="Broker: stopped", foreground="#cc4444")


class VisualsLogTab(ttk.Frame):
    def __init__(self, master):
        super().__init__(master, padding=8)

        toolbar = ttk.Frame(self)
        toolbar.pack(fill="x", pady=(0, 6))
        ttk.Label(toolbar, text="Logs every 2 seconds", foreground="#888888").pack(side="left")
        ttk.Button(toolbar, text="Clear Logs", command=self.clear).pack(side="right")

        self.text = tk.Text(
            self, bg=DARK_BG, fg=FG_MAIN, insertbackground=FG_MAIN,
            font=("Consolas", 11), wrap="word", state="disabled", bd=0
        )
        self.text.pack(fill="both", expand=True)
        self.text.tag_configure("label", foreground="#9aa0a6")
        # Numbers get a bright, high-contrast color for readability
        self.text.tag_configure("num", foreground="#00e5ff", font=("Consolas", 11, "bold"))

    def push(self, segments):
        self.text.configure(state="normal")
        for seg_text, seg_tag in segments:
            self.text.insert("end", seg_text, seg_tag)
        self.text.insert("end", "\n")
        self.text.see("end")
        self.text.configure(state="disabled")

    def clear(self):
        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        self.text.configure(state="disabled")


class InstructorLogTab(ttk.Frame):
    def __init__(self, master):
        super().__init__(master, padding=8)

        toolbar = ttk.Frame(self)
        toolbar.pack(fill="x", pady=(0, 6))
        ttk.Label(toolbar, text="Command traffic only \u2014 continuous state stream is not logged",
                  foreground="#888888").pack(side="left")
        ttk.Button(toolbar, text="Clear Logs", command=self.clear).pack(side="right")

        self.text = tk.Text(
            self, bg=DARK_BG, fg=FG_MAIN, insertbackground=FG_MAIN,
            font=("Consolas", 11), wrap="word", state="disabled", bd=0
        )
        self.text.pack(fill="both", expand=True)
        self.text.tag_configure("received", foreground="#33cc66")   # green
        self.text.tag_configure("sent", foreground="#3399ff")       # blue
        self.text.tag_configure("warn", foreground="#ffaa00")
        self.text.tag_configure("normal", foreground=FG_MAIN)

    def push(self, text, tag):
        self.text.configure(state="normal")
        self.text.insert("end", text + "\n", tag)
        self.text.see("end")
        self.text.configure(state="disabled")

    def clear(self):
        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        self.text.configure(state="disabled")


class RadarLogTab(ttk.Frame):
    def __init__(self, master):
        super().__init__(master, padding=8)

        toolbar = ttk.Frame(self)
        toolbar.pack(fill="x", pady=(0, 6))
        self.info_lbl = ttk.Label(
            toolbar,
            text=f"Forwarding blips & land sweeps -> {CFG.RADAR_IP}:{CFG.RADAR_PORT}",
            foreground="#888888"
        )
        self.info_lbl.pack(side="left")
        ttk.Button(toolbar, text="Clear Logs", command=self.clear).pack(side="right")

        self.text = tk.Text(
            self, bg=DARK_BG, fg=FG_MAIN, insertbackground=FG_MAIN,
            font=("Consolas", 11), wrap="word", state="disabled", bd=0
        )
        self.text.pack(fill="both", expand=True)
        self.text.tag_configure("blip", foreground="#33cc66")   # green - contact blips
        self.text.tag_configure("land", foreground="#c084fc")   # purple - land sweeps
        self.text.tag_configure("info", foreground="#3399ff")   # blue - status/info
        self.text.tag_configure("warn", foreground="#ffaa00")
        self.text.tag_configure("normal", foreground=FG_MAIN)

    def push(self, text, tag):
        self.text.configure(state="normal")
        self.text.insert("end", text + "\n", tag)
        self.text.see("end")
        self.text.configure(state="disabled")

    def refresh_target(self):
        self.info_lbl.configure(text=f"Forwarding blips & land sweeps -> {CFG.RADAR_IP}:{CFG.RADAR_PORT}")

    def clear(self):
        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        self.text.configure(state="disabled")


class PlaceholderTab(ttk.Frame):
    def __init__(self, master, name):
        super().__init__(master, padding=8)
        ttk.Label(
            self, text=f"{name}\n\n(No functionality yet \u2014 reserved for future use)",
            justify="center", foreground="#888888", font=("Segoe UI", 11)
        ).place(relx=0.5, rely=0.5, anchor="center")

        bottom_frame = ttk.Frame(self)
        bottom_frame.pack(side="bottom", fill="x", pady=(6, 0))
        ttk.Button(bottom_frame, text="Clear Logs", state="disabled").pack(side="right")


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Vessel Simulation Broker - Monitor")
        self.geometry("880x600")

        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass

        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True)

        self.settings_tab = SettingsTab(notebook, self)
        self.visuals_tab = VisualsLogTab(notebook)
        self.instructor_tab = InstructorLogTab(notebook)
        self.radar_tab = RadarLogTab(notebook)
        self.ecdis_tab = PlaceholderTab(notebook, "ECDIS Logs")

        notebook.add(self.settings_tab, text="Settings")
        notebook.add(self.visuals_tab, text="Visuals Logs")
        notebook.add(self.instructor_tab, text="Instructor Logs")
        notebook.add(self.radar_tab, text="Radar Logs")
        notebook.add(self.ecdis_tab, text="ECDIS Logs")

        self.protocol("WM_DELETE_WINDOW", self.on_close)
        self.after(150, self.poll_visuals)
        self.after(150, self.poll_instructor)
        self.after(150, self.poll_radar)

        # Auto-start the broker on launch
        self.after(300, self._auto_start)

    def _auto_start(self):
        try:
            broker.start()
            self.settings_tab.set_status(True)
            self.radar_tab.refresh_target()
        except OSError as e:
            log_instructor(f"\u274c Auto-start failed: {e}", "warn")
            self.settings_tab.set_status(False)

    def poll_visuals(self):
        try:
            while True:
                segments = visuals_queue.get_nowait()
                self.visuals_tab.push(segments)
        except queue.Empty:
            pass
        self.after(150, self.poll_visuals)

    def poll_instructor(self):
        try:
            while True:
                text, tag = instructor_queue.get_nowait()
                self.instructor_tab.push(text, tag)
        except queue.Empty:
            pass
        self.after(150, self.poll_instructor)

    def poll_radar(self):
        try:
            while True:
                text, tag = radar_queue.get_nowait()
                self.radar_tab.push(text, tag)
        except queue.Empty:
            pass
        self.after(150, self.poll_radar)

    def on_close(self):
        broker.stop()
        self.destroy()


if __name__ == "__main__":
    app = App()
    app.mainloop()