const print = @import("std").debug.print;
const c = @import("c.zig").c;
const Global = @import("Global.zig");
const err = @import("err.zig");

var quit: bool = false;

var shader_program: u32 = undefined;

var vao: u32 = undefined; // vertex array object
var vbo: u32 = undefined; // vertex buffer object

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

fn input() void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => quit = true,
            c.SDL_EVENT_WINDOW_RESIZED => {
                var w: c_int = 0;
                var h: c_int = 0;
                _ = c.SDL_GetWindowSize(Global.window, &w, &h);

                if (w != 0 and h != 0)
                    c.glViewport(0, 0, w, h);
            },
            c.SDL_EVENT_KEY_UP => {
                switch (event.key.key) {
                    c.SDLK_ESCAPE => quit = true,
                    // c.SDLK_1 => c.glClearColor(0, 0, 0, 1),
                    // c.SDLK_2 => c.glClearColor(1, 1, 1, 1),

                    else => {},
                }
            },
            else => {},
        }
    }
}

fn draw() void {
    c.glClearColor(0, 0.5, 0.5, 1);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    c.glUseProgram(shader_program);
    c.glBindVertexArray(vao);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

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
    _ = c.SDL_GL_SetSwapInterval(1);

    Global.window = c.SDL_CreateWindow(
        "OpenGL Window",
        600,
        600,
        c.SDL_WINDOW_OPENGL,
    ) orelse return err.SDL.init;
    defer c.SDL_DestroyWindow(Global.window);

    const glContext = c.SDL_GL_CreateContext(Global.window) orelse return err.SDL.init;
    defer _ = c.SDL_GL_DestroyContext(glContext);

    const version = c.gladLoadGLLoader(@ptrCast(&c.SDL_GL_GetProcAddress));
    if (version == 0) return err.SDL.init;

    // initialization code
    c.glViewport(0, 0, 600, 600);

    // creating and linking shaders
    const vertex_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, @ptrCast(&vertex_shader_source), null);
    c.glCompileShader(vertex_shader);
    try shaderDidCompile(vertex_shader);

    const fragment_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, @ptrCast(&fragment_shader_source), null);
    c.glCompileShader(fragment_shader);
    try shaderDidCompile(fragment_shader);

    shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);
    try shadersDidLink(shader_program);

    // dont need the shaders anymore after attaching
    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    // create a vao and bind it to a vbo and attribute pointer
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    const triangle_vertices = [_]f32{
        -0.5, -0.5, 0,
        0.5,  -0.5, 0,
        0.0,  0.5,  0,
    };

    c.glBindVertexArray(vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, triangle_vertices.len * @sizeOf(f32), &triangle_vertices[0], c.GL_STATIC_DRAW);

    // tell openGL how to interpret the data from vertex buffer
    c.glVertexAttribPointer(
        0, // index of vertex attribute (see vertex_shader_source, must align with what we have there)
        3, // size (1,2,3,4) vec3 in this case
        c.GL_FLOAT, // data type
        c.GL_FALSE, // normalize data?
        3 * @sizeOf(f32), // stride (space between consecutive vertex attributes)
        @ptrFromInt(0), // offset of where the position data begins in the buffer
    );
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    while (!quit) {
        input();
        draw();
    }
}

fn shaderDidCompile(shader: u32) err.GL!void {
    var success: c_int = 0;
    var infoLog: [512]u8 = .{' '} ** 512;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);

    if (success == 0) {
        var len: usize = 0;
        c.glGetShaderInfoLog(shader, infoLog.len, @ptrCast(&len), &infoLog);
        print("Shader compilation error: {s}\n", .{infoLog[0..len]});
        return err.GL.shader_compilation;
    }
}

fn shadersDidLink(program: u32) err.GL!void {
    var success: c_int = 0;
    var infoLog: [512]u8 = .{' '} ** 512;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);

    if (success == 0) {
        var len: usize = 0;
        c.glGetProgramInfoLog(program, 512, @ptrCast(&len), &infoLog);
        print("Shader linking error: {s}\n", .{infoLog[0..len]});
        return err.GL.shader_linking;
    }
}
