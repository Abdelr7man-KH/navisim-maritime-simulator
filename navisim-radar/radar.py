import pygame
import time
import math
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import ThreadingOSCUDPServer
import threading

# --- CONFIGURATION ---
WIDTH, HEIGHT = 700, 700
CENTER = (WIDTH // 2, HEIGHT // 2)

# SCALING LOGIC (Unified Range)
MAX_RANGE = 50000.0 
MARGIN = 50  # Pixels of padding around the edge for the text
RADAR_RADIUS = (WIDTH // 2) - MARGIN
SCALE = RADAR_RADIUS / MAX_RANGE  

IP = "0.0.0.0"
PORT = 5006

# --- GLOBALS ---
ships = {}       
land_points = [] 

# --- OSC HANDLERS ---
def blip_handler(address, *args):
    """ Receives the Multi-Sphere Trace ship data """
    if len(args) >= 3:
        name = args[0]
        rel_x = args[1]
        rel_y = args[2]
        ships[name] = (rel_x, rel_y, time.time())

def land_handler(address, *args):
    """ Receives the full Raycast sweep array """
    global land_points
    new_points = []
    
    for i in range(0, len(args), 2):
        if i + 1 < len(args): 
            new_points.append((args[i], args[i+1]))
            
    land_points = new_points

def start_osc_server():
    dispatcher = Dispatcher()
    dispatcher.map("/radar/blip", blip_handler)
    dispatcher.map("/radar/land", land_handler)
    server = ThreadingOSCUDPServer((IP, PORT), dispatcher)
    print(f"OSC Server listening on {IP}:{PORT}")
    server.serve_forever()

# --- START OSC THREAD ---
osc_thread = threading.Thread(target=start_osc_server, daemon=True)
osc_thread.start()

# --- INITIALIZE PYGAME ---
pygame.init()
pygame.font.init() # Initialize the font module
font = pygame.font.SysFont('Consolas', 14, bold=True) # Monospace font for radar numbers

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Live Topological Radar - Compass HUD")
clock = pygame.time.Clock()

running = True
while running:
    # 1. HANDLE EVENTS
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # 2. DRAW BACKGROUND
    screen.fill((2, 10, 2)) # Very dark naval background

    # 3. DRAW RADAR UI (Rings and Compass Bearings)
    # Draw 5 evenly spaced inner range rings (Thickness increased to 2)
    for r in range(1, 6):
        px_r = int((r / 5.0) * RADAR_RADIUS)
        pygame.draw.circle(screen, (0, 60, 0), CENTER, px_r, 2)

    # Draw Outer Compass Ring & Ticks
    for angle in range(0, 360, 10):
        # Subtract 90 so 0 degrees is at the Top (North)
        rad = math.radians(angle - 90) 
        
        # Point exactly on the outer circle
        start_x = CENTER[0] + math.cos(rad) * RADAR_RADIUS
        start_y = CENTER[1] + math.sin(rad) * RADAR_RADIUS
        
        if angle % 30 == 0:
            # Draw a longer tick mark every 30 degrees
            end_x = CENTER[0] + math.cos(rad) * (RADAR_RADIUS + 8)
            end_y = CENTER[1] + math.sin(rad) * (RADAR_RADIUS + 8)
            
            # Render the degree text (zfill makes '0' into '000')
            text = font.render(str(angle).zfill(3), True, (0, 180, 0))
            # Push the text out further than the tick mark
            text_rect = text.get_rect(center=(
                CENTER[0] + math.cos(rad) * (RADAR_RADIUS + 25), 
                CENTER[1] + math.sin(rad) * (RADAR_RADIUS + 25)
            ))
            screen.blit(text, text_rect)
        else:
            # Draw a short tick mark for 10 and 20 degree intervals
            end_x = CENTER[0] + math.cos(rad) * (RADAR_RADIUS + 4)
            end_y = CENTER[1] + math.sin(rad) * (RADAR_RADIUS + 4)
            
        pygame.draw.line(screen, (0, 100, 0), (start_x, start_y), (end_x, end_y), 2)

    # Draw Crosshairs inside the radar radius (Thickness increased to 2)
    pygame.draw.line(screen, (0, 60, 0), (CENTER[0], CENTER[1] - RADAR_RADIUS), (CENTER[0], CENTER[1] + RADAR_RADIUS), 2)
    pygame.draw.line(screen, (0, 60, 0), (CENTER[0] - RADAR_RADIUS, CENTER[1]), (CENTER[0] + RADAR_RADIUS, CENTER[1]), 2)

    # 4. DRAW LANDMASSES 
    for rel_x, rel_y in land_points:
        scr_x = CENTER[0] + int(rel_y * SCALE)
        scr_y = CENTER[1] - int(rel_x * SCALE)
        
        # Only draw if inside the radar circle
        if math.dist(CENTER, (scr_x, scr_y)) <= RADAR_RADIUS:
            pygame.draw.circle(screen, (150, 150, 50), (scr_x, scr_y), 2)

    # 5. DRAW SHIPS 
    current_time = time.time()
    stale_ships = []
    
    for name, pos_data in list(ships.items()):
        rel_x, rel_y, last_seen = pos_data
        
        if current_time - last_seen > 2.0:
            stale_ships.append(name)
            continue
            
        scr_x = CENTER[0] + int(rel_y * SCALE)
        scr_y = CENTER[1] - int(rel_x * SCALE)

        # Only draw if inside the radar circle
        if math.dist(CENTER, (scr_x, scr_y)) <= RADAR_RADIUS:
            # Ship color changed to Cyan (0, 255, 255)
            pygame.draw.rect(screen, (0, 255, 255), (scr_x - 3, scr_y - 3, 6, 6))

    for name in stale_ships:
        del ships[name]

    # 6. DRAW PLAYER SHIP
    pygame.draw.circle(screen, (0, 255, 0), CENTER, 3)

    pygame.display.flip()
    clock.tick(60)

pygame.quit()