from microbit import *
import music
import random
import radio

# ========== Game Constants ==========
GRID_WIDTH = 5
GRID_HEIGHT = 5
DEFAULT_TICK_RATE = 700
MIN_TICK_RATE = 200
SPEED_INCREASE = 25
TEMPERATURE_THRESHOLD = 30
SOUND_THRESHOLD = 150
RADIO_GROUP = 22
HIGH_SCORE_FILE = "tetris_hs"

DROP_SHAPES = [
    [(0,0)], # Single block
    [(0,0), (0,1)], # Vertical line
    [(0,0), (1,0)], # Horizontal line
    [(0,0), (1,0), (1,1)], # L shape
    [(0,0), (1,0), (0,1)], # Reverse L
    [(0,0), (1,0), (0,1), (1,1)] # Square
]

STATE_MENU = 0
STATE_PLAYING = 1
STATE_PAUSED = 2
STATE_GAME_OVER = 3

MODE_CLASSIC = 0
MODE_TILT = 1
MODE_BATTLE = 2
MODE_HARDCORE = 3
MODE_NAMES = ["CLASSIC", "TILT", "BATTLE", "HARDCORE"]

class TetrisGame:
    def __init__(self):
        self.grid = [[0] * GRID_WIDTH for _ in range(GRID_HEIGHT)]
        self.current_piece = None
        self.piece_x = 2
        self.piece_y = 0
        self.score = 0
        self.high_score = self._load_high_score()
        self.game_state = STATE_MENU
        self.game_mode = MODE_CLASSIC
        self.last_tick = running_time()
        self.drop_speed = DEFAULT_TICK_RATE
        self.tilt_calibration = accelerometer.get_x()
        self.fire_mode = False
        self.fire_mode_timer = 0
        self.last_fire_time = 0  # cooldown for fire mode
        self.gravity_mode = False
        self.gravity_direction = 0
        self.pending_garbage = 0
        self.menu_selection = 0
        radio.config(group=RADIO_GROUP, queue=6)
        radio.off()

    def _load_high_score(self):
        try:
            with open(HIGH_SCORE_FILE, 'r') as f:
                return int(f.read())
        except:
            return 0

    def _save_high_score(self):
        try:
            with open(HIGH_SCORE_FILE, 'w') as f:
                f.write(str(self.high_score))
        except:
            pass

    def init_game(self):
        self.grid = [[0] * GRID_WIDTH for _ in range(GRID_HEIGHT)]
        self.score = 0
        self.game_state = STATE_PLAYING
        self.drop_speed = DEFAULT_TICK_RATE
        self.fire_mode = False
        self.fire_mode_timer = 0
        self.gravity_mode = False
        self.gravity_direction = 0
        self.pending_garbage = 0
        if self.game_mode == MODE_BATTLE:
            radio.on()
        else:
            radio.off()
        display.show(Image.DIAMOND)
        sleep(300)
        display.show(Image.DIAMOND_SMALL)
        sleep(300)
        self.spawn_piece()

    def spawn_piece(self):
        self.current_piece = random.choice(DROP_SHAPES)
        max_piece_x = max(px for px, py in self.current_piece)
        self.piece_x = random.randint(0, GRID_WIDTH - 1 - max_piece_x)
        self.piece_y = 0
        if not self.is_valid_position(self.piece_x, self.piece_y):
            self.game_state = STATE_GAME_OVER
            music.play(music.WAWAWAWAA)
            if self.score > self.high_score:
                self.high_score = self.score
                self._save_high_score()
                display.scroll("NEW HIGH SCORE!")

    def is_valid_position(self, x, y, piece=None):
        if piece is None:
            piece = self.current_piece
        for px, py in piece:
            gx, gy = x + px, y + py
            if gx < 0 or gx >= GRID_WIDTH or gy < 0 or gy >= GRID_HEIGHT:
                return False
            if self.grid[gy][gx]:
                return False
        return True

    def rotate_piece(self):
        # Don't rotate single block or square
        if len(self.current_piece) <= 1 or (len(self.current_piece) == 4 and self.current_piece[0] == (0,0) and self.current_piece[3] == (1,1)):
            return
        rotated = [(-py, px) for px, py in self.current_piece]
        min_x = min(x for x, y in rotated)
        min_y = min(y for x, y in rotated)
        normalized = [(x - min_x, y - min_y) for x, y in rotated]
        if self.is_valid_position(self.piece_x, self.piece_y, normalized):
            self.current_piece = normalized
            music.pitch(1200, 10, wait=False)

    def move_piece(self, dx, dy):
        if self.is_valid_position(self.piece_x + dx, self.piece_y + dy):
            self.piece_x += dx
            self.piece_y += dy
            return True
        return False

    def place_piece(self):
        for px, py in self.current_piece:
            gx, gy = self.piece_x + px, self.piece_y + py
            if 0 <= gx < GRID_WIDTH and 0 <= gy < GRID_HEIGHT:
                self.grid[gy][gx] = 1
        music.pitch(900, 15, wait=False)
        if self.game_mode == MODE_HARDCORE:
            self.drop_speed = max(MIN_TICK_RATE, self.drop_speed - SPEED_INCREASE * 2)
        else:
            self.drop_speed = max(MIN_TICK_RATE, self.drop_speed - SPEED_INCREASE)

    def clear_lines(self):
        new_grid = []
        lines_cleared = 0
        for row in self.grid:
            if all(cell == 1 for cell in row):
                lines_cleared += 1
            else:
                new_grid.append(row)
        while len(new_grid) < GRID_HEIGHT:
            new_grid.insert(0, [0] * GRID_WIDTH)
        self.grid = new_grid
        line_scores = [0, 40, 100, 300, 800]
        self.score += line_scores[min(lines_cleared, 4)] * (2 if self.game_mode == MODE_HARDCORE else 1)
        if lines_cleared > 0:
            display.clear()
            for i in range(5):
                display.show(Image.DIAMOND)
                sleep(50)
                display.clear()
                sleep(50)
            if lines_cleared == 1:
                music.play(music.POWER_UP)
            elif lines_cleared == 2:
                music.play(music.POWER_UP, wait=False)
                music.play(music.JUMP_UP)
            elif lines_cleared >= 3:
                music.play(music.NYAN)
            if self.game_mode == MODE_BATTLE and lines_cleared > 1:
                radio.send("GARBAGE:" + str(lines_cleared - 1))

    def add_garbage(self, amount):
        for i in range(amount):
            self.grid.insert(0, self.grid.pop())
            hole = random.randint(0, GRID_WIDTH - 1)
            for x in range(GRID_WIDTH):
                self.grid[GRID_HEIGHT - 1][x] = 0 if x == hole else 1
        music.play(music.WAWAWAWAA, wait=False)

    def instant_drop(self):
        moved = True
        while moved:
            moved = self.move_piece(0, 1)
        self.place_piece()
        self.clear_lines()
        self.spawn_piece()
        music.pitch(1500, 50, wait=False)

    def rotate_gravity(self):
        self.gravity_direction = (self.gravity_direction + 1) % 4
        arrows = [Image.ARROW_S, Image.ARROW_E, Image.ARROW_N, Image.ARROW_W]
        display.show(arrows[self.gravity_direction])
        sleep(300)
        music.play(music.SLIDE)

    def scramble_board(self):
        block_count = sum(sum(row) for row in self.grid)
        new_grid = [[0] * GRID_WIDTH for _ in range(GRID_HEIGHT)]
        blocks_placed = 0
        while blocks_placed < block_count:
            x, y = random.randint(0, GRID_WIDTH - 1), random.randint(0, GRID_HEIGHT - 1)
            if new_grid[y][x] == 0:
                new_grid[y][x] = 1
                blocks_placed += 1
        self.grid = new_grid
        display.show(Image.DIAMOND)
        sleep(100)
        display.show(Image.DIAMOND_SMALL)
        sleep(100)
        display.show(Image.DIAMOND)
        sleep(100)

    def activate_fire_mode(self):
        self.grid[GRID_HEIGHT - 1] = [0] * GRID_WIDTH
        self.fire_mode = True
        self.fire_mode_timer = running_time() + 5000
        display.show(Image.TRIANGLE)
        music.play(music.DADADADUM)

    def draw_grid(self):
        display.clear()
        for y in range(GRID_HEIGHT):
            for x in range(GRID_WIDTH):
                if self.grid[y][x]:
                    if self.fire_mode and y >= GRID_HEIGHT - 2:
                        display.set_pixel(x, y, 9)
                    else:
                        display.set_pixel(x, y, 7)
        for px, py in self.current_piece:
            gx, gy = self.piece_x + px, self.piece_y + py
            if 0 <= gx < GRID_WIDTH and 0 <= gy < GRID_HEIGHT:
                display.set_pixel(gx, gy, 9)

    def draw_menu(self):
        display.scroll(MODE_NAMES[self.menu_selection], delay=80, wait=True, loop=False)
        display.clear()

    def draw_paused(self):
        display.show(Image.DIAMOND if (running_time() // 500) % 2 else Image.DIAMOND_SMALL)

    def draw_game_over(self):
        if (running_time() // 500) % 2:
            display.show(Image.SKULL)
        else:
            display.clear()
            score_pixels = min(25, max(1, self.score // 20))
            for i in range(score_pixels):
                y = i // 5
                x = i % 5
                display.set_pixel(x, y, 9)

    def handle_buttons(self):
        if self.game_state == STATE_PLAYING:
            if button_a.was_pressed():
                if self.game_mode == MODE_TILT:
                    self.move_piece(-1, 0)
                else:
                    self.rotate_piece()
            if button_b.was_pressed():
                self.move_piece(1, 0)
            if button_a.is_pressed() and button_b.is_pressed():
                self.instant_drop()
            try:
                if pin_logo.is_touched():
                    self.game_state = STATE_PAUSED
                    display.show(Image.SQUARE_SMALL)
                    sleep(500)
            except:
                pass
        elif self.game_state == STATE_PAUSED:
            if button_a.was_pressed() or button_b.was_pressed():
                self.game_state = STATE_PLAYING
                sleep(300)
        elif self.game_state == STATE_MENU:
            if button_a.was_pressed():
                self.menu_selection = (self.menu_selection - 1) % len(MODE_NAMES)
            if button_b.was_pressed():
                self.menu_selection = (self.menu_selection + 1) % len(MODE_NAMES)
            if button_a.is_pressed() and button_b.is_pressed():
                self.game_mode = self.menu_selection
                self.init_game()
        elif self.game_state == STATE_GAME_OVER:
            if button_a.was_pressed() or button_b.was_pressed():
                self.game_state = STATE_MENU
                sleep(300)

    def handle_tilt(self):
        if self.game_state == STATE_PLAYING and (self.game_mode == MODE_TILT or self.game_mode == MODE_HARDCORE):
            x_tilt = accelerometer.get_x() - self.tilt_calibration
            if x_tilt < -300:
                self.move_piece(-1, 0)
                sleep(150)
            elif x_tilt > 300:
                self.move_piece(1, 0)
                sleep(150)

    def handle_sensors(self):
        if self.game_state != STATE_PLAYING:
            return
        current_time = running_time()
        # Fire mode cooldown: only once every 10 seconds
        if (temperature() > TEMPERATURE_THRESHOLD and not self.fire_mode and
            current_time - self.last_fire_time > 10000):
            self.activate_fire_mode()
            self.last_fire_time = current_time
        if self.fire_mode and current_time > self.fire_mode_timer:
            self.fire_mode = False
        try:
            if microphone.sound_level() > SOUND_THRESHOLD:
                self.instant_drop()
                sleep(300)
        except:
            pass
        try:
            heading = compass.heading()
            if 350 <= heading or heading <= 10:
                if not self.gravity_mode:
                    self.gravity_mode = True
                    self.rotate_gravity()
                    sleep(500)
        except:
            pass
        if accelerometer.was_gesture("shake"):
            self.scramble_board()
            sleep(500)

    def handle_radio(self):
        if self.game_mode != MODE_BATTLE:
            return
        msg = radio.receive()
        if msg:
            if msg.startswith("GARBAGE:"):
                try:
                    amount = int(msg.split(":")[1])
                    self.add_garbage(min(amount, 3))
                except:
                    pass

    def update(self):
        current_time = running_time()
        self.handle_radio()
        if self.game_state == STATE_PLAYING:
            if current_time - self.last_tick > self.drop_speed:
                moved = self.move_piece(0, 1)
                if not moved:
                    self.place_piece()
                    self.clear_lines()
                    self.spawn_piece()
                self.last_tick = current_time
            self.handle_sensors()
            self.draw_grid()
        elif self.game_state == STATE_MENU:
            self.draw_menu()
        elif self.game_state == STATE_PAUSED:
            self.draw_paused()
        elif self.game_state == STATE_GAME_OVER:
            self.draw_game_over()
        self.handle_buttons()
        if self.game_mode == MODE_TILT or self.game_mode == MODE_HARDCORE:
            self.handle_tilt()

def main():
    display.scroll("TETRIS+", delay=80)
    game = TetrisGame()
    try:
        while True:
            game.update()
            sleep(50)
    except Exception as e:
        display.scroll("ERROR")
        display.scroll(str(e))

if __name__ == "__main__":
    main()
