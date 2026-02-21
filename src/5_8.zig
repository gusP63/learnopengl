const print = @import("std").debug.print;
const c = @import("c.zig").c;
const Global = @import("Global.zig");
const err = @import("err.zig");

const Self = @This();

const vertex_shader_source =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\ gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

// 3.
const fragment_shader_yellow_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
    \\}
;

const two_triangles = [_]f32{
    // 1
    0.25,  -0.25, 0,
    0.75,  -0.25, 0,
    0.5,   0.75,  0,
    // 2
    -0.25, -0.25, 0,
    -0.75, -0.25, 0,
    -0.5,  0.75,  0,
};

const tri_1 = [_]f32{
    -0.25, -0.25, 0,
    -0.75, -0.25, 0,
    -0.5,  0.75,  0,
};

const tri_2 = [_]f32{
    0.25, -0.25, 0,
    0.75, -0.25, 0,
    0.5,  0.75,  0,
};

quit: bool = false,
gl_context: c.SDL_GLContext = undefined,
shader_program_orange: u32 = undefined,
shader_program_yellow: u32 = undefined,

// 1.
vao_g: u32 = undefined,
vbo_g: u32 = undefined,

// 2.
vao_t1: u32 = undefined,
vbo_t1: u32 = undefined,
vao_t2: u32 = undefined,
vbo_t2: u32 = undefined,

pub fn main() !void {
    var app: Self = .{};
    try app.init();
    defer app.deinit();

    while (!app.quit) {
        app.input();
        app.draw();
    }
}

fn input(self: *Self) void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => self.quit = true,
            else => {},
        }
    }
}

fn draw(self: *Self) void {
    c.glClearColor(0, 0.5, 0.5, 1);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    // 1.
    // c.glUseProgram(self.shader_program_orange);
    // c.glBindVertexArray(self.vao_g);
    // c.glDrawArrays(c.GL_TRIANGLES, 0, two_triangles.len / 3);

    // 2 and 3.
    c.glUseProgram(self.shader_program_orange);
    c.glBindVertexArray(self.vao_t1);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    c.glUseProgram(self.shader_program_yellow);
    c.glBindVertexArray(self.vao_t2);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    _ = c.SDL_GL_SwapWindow(Global.window);
}

fn compileShaders(self: *Self) !void {
    const vertex_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, @ptrCast(&vertex_shader_source), null);
    c.glCompileShader(vertex_shader);
    try Global.shaderDidCompile(vertex_shader);

    const fragment_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, @ptrCast(&fragment_shader_source), null);
    c.glCompileShader(fragment_shader);
    try Global.shaderDidCompile(fragment_shader);

    const fragment_shader_yellow: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader_yellow, 1, @ptrCast(&fragment_shader_yellow_source), null);
    c.glCompileShader(fragment_shader_yellow);
    try Global.shaderDidCompile(fragment_shader_yellow);

    self.shader_program_orange = c.glCreateProgram();
    c.glAttachShader(self.shader_program_orange, vertex_shader);
    c.glAttachShader(self.shader_program_orange, fragment_shader);
    c.glLinkProgram(self.shader_program_orange);
    try Global.shadersDidLink(self.shader_program_orange);

    self.shader_program_yellow = c.glCreateProgram();
    c.glAttachShader(self.shader_program_yellow, vertex_shader);
    c.glAttachShader(self.shader_program_yellow, fragment_shader_yellow);
    c.glLinkProgram(self.shader_program_yellow);
    try Global.shadersDidLink(self.shader_program_yellow);

    // dont need the shaders anymore after attaching
    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);
    c.glDeleteShader(fragment_shader_yellow);
}

fn init(self: *Self) !void {
    // sdl
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return err.SDL.init;
    errdefer print("{s}", .{c.SDL_GetError()});

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetSwapInterval(1);

    Global.window = c.SDL_CreateWindow(
        "OpenGL Window",
        Global.width,
        Global.height,
        c.SDL_WINDOW_OPENGL,
    ) orelse return err.SDL.init;
    self.gl_context = c.SDL_GL_CreateContext(Global.window) orelse return err.SDL.init;

    // glad
    const version = c.gladLoadGLLoader(@ptrCast(&c.SDL_GL_GetProcAddress));
    if (version == 0) return err.SDL.init;

    // opengl
    c.glViewport(0, 0, Global.width, Global.height);
    try self.compileShaders();

    // 1.
    c.glGenVertexArrays(1, &self.vao_g);
    c.glGenBuffers(1, &self.vbo_g);

    c.glBindVertexArray(self.vao_g);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo_g);

    c.glBufferData(c.GL_ARRAY_BUFFER, two_triangles.len * @sizeOf(f32), &two_triangles, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    // 2.
    // todo: figure out how to make this work
    // var vaos = [_]*u32{ &self.vao_t1, &self.vao_t2 };
    // var vbos = [_]*u32{ &self.vbo_t1, &self.vbo_t2 };
    // c.glGenVertexArrays(2, @ptrCast(&vaos));
    // c.glGenBuffers(2, @ptrCast(&vbos));

    c.glGenVertexArrays(1, &self.vao_t1);
    c.glGenVertexArrays(1, &self.vao_t2);
    c.glGenBuffers(1, &self.vbo_t1);
    c.glGenBuffers(1, &self.vbo_t2);

    // t1
    c.glBindVertexArray(self.vao_t1);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo_t1);
    c.glBufferData(c.GL_ARRAY_BUFFER, tri_1.len * @sizeOf(f32), &tri_1, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    // t2
    c.glBindVertexArray(self.vao_t2);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo_t2);
    c.glBufferData(c.GL_ARRAY_BUFFER, tri_2.len * @sizeOf(f32), &tri_2, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);
}

fn deinit(self: *Self) void {
    c.SDL_Quit();
    c.SDL_DestroyWindow(Global.window);
    _ = c.SDL_GL_DestroyContext(self.gl_context);
}
