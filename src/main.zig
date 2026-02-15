const print = @import("std").debug.print;
const c = @import("c.zig").c;
const Global = @import("Global.zig");
const err = @import("err.zig");

var quit: bool = false;

fn input() void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => quit = true,
            else => {},
        }
    }
}

fn draw() void {
    _ = c.glClearColor(0.2, 0.5, 0.8, 1);
    _ = c.glClear(c.GL_COLOR_BUFFER_BIT);
    _ = c.SDL_GL_SwapWindow(Global.window);
}

pub fn main() !void {
    errdefer print("{s}", .{c.SDL_GetError()});

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return err.SDL.init;
    defer c.SDL_Quit();

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);

    Global.window = c.SDL_CreateWindow("OpenGL Window", 600, 600, c.SDL_WINDOW_OPENGL) orelse return err.SDL.init;
    defer c.SDL_DestroyWindow(Global.window);

    const glContext = c.SDL_GL_CreateContext(Global.window) orelse return err.SDL.init;
    defer _ = c.SDL_GL_DestroyContext(glContext);

    // const version = c.gladLoadGLLoader(c.SDL_GL_GetProcAddress);
    const version = c.gladLoadGL();
    if (version == 0) return err.SDL.init;

    while (!quit) {
        input();
        draw();
    }
}
