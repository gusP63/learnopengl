const std = @import("std");
const err = @import("err.zig");
const c = @import("c.zig").c;

pub const Shader = struct {
    id: u32,

    pub fn create(
        vertex_source: []const u8,
        fragment_source: []const u8,
    ) !Shader {
        const flags: std.fs.File.OpenFlags = .{ .mode = .read_only };
        const v_file: std.fs.File = try std.fs.Dir.openFile(std.fs.cwd(), vertex_source, flags);
        defer v_file.close();
        const f_file: std.fs.File = try std.fs.Dir.openFile(std.fs.cwd(), fragment_source, flags);
        defer f_file.close();

        var v_buffer: [1024]u8 = undefined;
        var f_buffer: [1024]u8 = undefined;
        var v_reader = std.fs.File.reader(v_file, &v_buffer);
        var f_reader = std.fs.File.reader(f_file, &f_buffer);

        const v_size = try v_reader.getSize();
        const f_size = try f_reader.getSize();

        _ = try v_reader.interface.peek(v_size);
        v_buffer[v_size] = 0;
        _ = try f_reader.interface.peek(f_size);
        f_buffer[f_size] = 0;

        const vert_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(vert_shader, 1, @ptrCast(&v_buffer[0..v_size]), null);
        c.glCompileShader(vert_shader);
        try shaderDidCompile(vert_shader);

        const frag_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(frag_shader, 1, @ptrCast(&f_buffer[0..f_size]), null);
        c.glCompileShader(frag_shader);
        try shaderDidCompile(frag_shader);

        const _id: u32 = c.glCreateProgram();

        c.glAttachShader(_id, vert_shader);
        c.glAttachShader(_id, frag_shader);
        c.glLinkProgram(_id);
        try shadersDidLink(_id);

        c.glDeleteShader(vert_shader);
        c.glDeleteShader(frag_shader);

        return .{ .id = _id };
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    fn shaderDidCompile(shader: u32) err.GL!void {
        var success: c_int = 0;
        var infoLog: [512]u8 = .{' '} ** 512;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);

        if (success == 0) {
            var len: usize = 0;
            c.glGetShaderInfoLog(shader, infoLog.len, @ptrCast(&len), &infoLog);
            std.debug.print("Shader compilation error: {s}\n", .{infoLog[0..len]});
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
            std.debug.print("Shader linking error: {s}\n", .{infoLog[0..len]});
            return err.GL.shader_linking;
        }
    }
};
