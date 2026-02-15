const c = @import("c.zig").c;

pub var window: *c.SDL_Window = undefined;
pub var glContext: *c.SDL_GLContextState = undefined;
