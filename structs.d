module structs;

import core.stdc.math : sqrt;
import core.stdc.wchar_ : wcscpy;
import core.stdc.stdio : puts;
import core.stdc.stdlib : abs;
import core.stdc.math : cbrt;

import core.sys.windows.windows;

import std.algorithm.mutation : swap;

version(tb)
{
enum G = 1.0f;
}

version(co)
{
enum G = 3.0f;
}

struct CONSOLE_FONT_INFOEX
{
    ULONG cbSize;
    DWORD nFont;
    COORD dwFontSize;
    UINT FontFamily;
    UINT FontWeight;
    WCHAR[LF_FACESIZE] FaceName;
}

extern (Windows) BOOL SetCurrentConsoleFontEx(HANDLE hConsoleOutput,
        BOOL bMaximumWindow, CONSOLE_FONT_INFOEX* lpConsoleCurrentFontEx);

enum WIDTH = 950;
enum HEIGHT = 670;
enum dW = 8;
enum dH = 8;

struct Body
{
    float r = 0.2f;
    float m = 1.0f;

    vec2 pos = 0;
    vec2 vel = 0;
    vec2 acc = 0;

    this(float m)
    {
        this.m = m;
        r = 0.2f * cbrt(m);
        pos = 0;
        vel = 0;
        acc = 0;
    }

    this(float m, float r)
    {
        this.r = r;
        this.m = m;
        pos = 0;
        vel = 0;
        acc = 0;
    }

    void setPos(float x, float y)
    {
        pos.x = x;
        pos.y = y;
    }

    void PulledBy(const ref Body other)
    {
        const float dist = sqrt((pos - other.pos) * (pos - other.pos));
        acc += ((other.pos - pos) / dist / dist / dist * (G * other.m) );
    }

    void Update(float dt)
    {
        vel += (acc * dt);
        pos += (vel * dt);
        acc = 0;
    }
}

struct Bright
{
    int n;
    const char[11] s;
}

struct Screen
{
    private bool[WIDTH][HEIGHT] canvas;
    private float x;
    private float y;
    private float zoom;
    private int _palette;

    public this(float x, float y, int z)
    {
        this.x = x;
        this.y = y;
        zoom = z;

        Setup();
        Clear();
    }

    public void Clear()
    {
        for (int i = 0; i < HEIGHT; i++)
            for (int j = 0; j < WIDTH; j++)
                canvas[i][j] = false;
    }

    public void PlotPoint(float x, float y)
    {
        int[2] pos;
        transform(pos.ptr, x, y);
        drawPoint(pos[0], pos[1]);
    }

    public void PlotLine(float x1, float y1, float x2, float y2)
    {
        int[2] pos1;
        int[2] pos2;
        transform(pos1.ptr, x1, y1);
        transform(pos2.ptr, x2, y2);
        drawLine(pos1[0], pos1[1], pos2[0], pos2[1]);
    }

    public void PlotCircle(float x, float y, float r)
    {
        int[2] p1;
        int[2] p2;

        transform(p1.ptr, x - r, y + r);
        transform(p2.ptr, x + r, y - r);

        for (int i = p1[0]; i <= p2[0]; i++)
        {
            for (int j = p1[1]; j <= p2[1]; j++)
            {
                float xt = cast(float)(j - WIDTH / 2) / zoom + this.x;
                float yt = cast(float)(HEIGHT / 2 - 1 - i) / zoom + this.y;
                const float radius2 = (xt - x) * (xt - x) + (yt - y) * (yt - y);

                if (radius2 <= r * r)
                {
                    drawPoint(i, j);
                }
            }
        }
    }

    public void PlotRectangle(float x1, float y1, float x2, float y2)
    {
        int[2] p1;
        int[2] p2;
        transform(p1.ptr, x1, y1);
        transform(p2.ptr, x2, y2);
        drawRectangle(p1[0], p1[1], p2[0], p2[1]);
    }

    public void Position(float x, float y)
    {
        this.x = x;
        this.y = y;
    }

    public void Zoom(float zoom)
    {
        this.zoom = zoom;
    }

    public void Draw()
    {
        char[WIDTH / dW + 1][HEIGHT / dH] frame;

        for (int i = 0; i < HEIGHT / dH - 1; ++i)
        {
            frame[i][WIDTH / dW] = '\n';
        }

        frame[HEIGHT / dH - 1][WIDTH / dW] = '\0';

        for (int i = 0; i < HEIGHT / dH; i++)
        {
            for (int j = 0; j < WIDTH / dW; j++)
            {
                int count = 0;
                for (int k = 0; k < dH; k++)
                {
                    for (int l = 0; l < dW; l++)
                    {
                        count += canvas[dH * i + k][dW * j + l];
                    }
                }

                frame[i][j] = brightness(count);
            }
        }

        for (int i = 0; i < HEIGHT / dH; ++i)
        {
            frame[i][0] = '@';
            frame[i][WIDTH / dW - 1] = '@';
        }

        for (int j = 0; j < WIDTH / dW; ++j)
        {
            frame[0][j] = '@';
            frame[HEIGHT / dH - 1][j] = '@';
        }

        FillScreenWithString(frame[0].ptr);
    }

    public void set_palette(int palette)
    {
        this._palette = palette;
    }

    pragma(lib, "user32");

    private void Setup()
    {
        CONSOLE_FONT_INFOEX cf;
        cf.cbSize = cast(ULONG)(cf.sizeof);
        cf.dwFontSize.X = cast(SHORT)(dW);
        cf.dwFontSize.Y = cast(SHORT)(dH);

        wcscpy(cf.FaceName.ptr, "Terminal");
        SetCurrentConsoleFontEx(GetStdHandle((cast(DWORD)-11)), 0, &cf);

        HWND console = GetConsoleWindow();
        RECT ConsoleRect;

        GetWindowRect(console, &ConsoleRect);
        MoveWindow(console, 0, 0, 1024, 768, 1);
    }

    private void FillScreenWithString(const(char)* frame)
    {
        COORD coord = COORD(0, 0);

        SetConsoleCursorPosition(GetStdHandle((cast(DWORD)-11)), coord);
        puts(frame);
    }

    private void transform(int* pos, float x, float y)
    {
        x = (x - this.x) * zoom + (WIDTH / 2);
        y = (y - this.y) * zoom + (HEIGHT / 2);

        pos[0] = cast(int)(HEIGHT - 1 - y);
        pos[1] = cast(int) x;
    }

    private void drawPoint(int A, int B)
    {
        if (A < 0 || B < 0 || A >= HEIGHT || B >= WIDTH)
        {
            return;
        }

        canvas[A][B] = true;
    }

    private void drawBoldPoint(int A, int B)
    {
        for (int i = A - 1; i <= A + 1; i++)
        {
            for (int j = B - 1; j <= B + 1; j++)
            {
                drawPoint(i, j);
            }
        }
    }

    private void drawLine(int A, int B, int C, int D)
    {
        if (A > C)
        {
            swap(A, C);
            swap(B, D);
        }

        if (B == D)
        {
            for (int i = A; i <= C; i++)
            {
                drawBoldPoint(i, B);
            }

            return;
        }

        if (A == C)
        {
            if (D < B)
            {
                swap(B, D);
            }

            for (int i = B; i <= D; ++i)
            {
                drawBoldPoint(A, i);
            }

            return;
        }

        if (abs(D - B) < abs(C - A))
        {
            drawLineLow(A, B, C, D);
        }
        else
        {
            if (B > D)
                drawLineHigh(C, D, A, B);
            else
                drawLineHigh(A, B, C, D);
        }
    }

    private void drawRectangle(int i1, int j1, int i2, int j2)
    {
        const int minI = i1 < i2 ? i1 : i2;
        const int maxI = i1 < i2 ? i2 : i1;
        const int minJ = j1 < j2 ? j1 : j2;
        const int maxJ = j1 < j2 ? j2 : j1;

        for (int i = minI; i <= maxI; i++)
        {
            for (int j = minJ; j <= maxJ; j++)
            {
                drawPoint(i, j);
            }
        }
    }

    private void drawLineLow(int x0, int y0, int x1, int y1)
    {
        const int dx = x1 - x0;
        int dy = y1 - y0;
        int yi = 1;

        if (dy < 0)
        {
            yi = -1;
            dy = -dy;
        }

        int D = 2 * dy - dx;
        int y2 = y0;

        for (int x2 = x0; x2 <= x1; x2++)
        {
            drawBoldPoint(x2, y2);

            if (D > 0)
            {
                y2 += yi;
                D -= 2 * dx;
            }

            D += 2 * dy;
        }

    }

    private void drawLineHigh(int x0, int y0, int x1, int y1)
    {
        int dx = x1 - x0;
        const int dy = y1 - y0;
        int xi = 1;

        if (dx < 0)
        {
            xi = -1;
            dx = -dx;
        }

        int D = 2 * dx - dy;
        int x2 = x0;

        for (int y2 = y0; y2 <= y1; y2++)
        {
            drawBoldPoint(x2, y2);

            if (D > 0)
            {
                x2 += xi;
                D -= 2 * dy;
            }

            D += 2 * dx;
        }
    }

    static const Bright[] p = [
        Bright(10, " .,:;oOQ#@"), Bright(10, "     .oO@@"), Bright(3, " .:")
    ];

    private char brightness(int count) const
    {
        if (_palette >= 0 && _palette <= 2)
        {
            return p[_palette].s[count * (p[_palette].n - 1) / dW / dH];
        }
        else
        {
            return ' ';
        }
    }
}

struct vec2
{
    float x = 0.0f;
    float y = 0.0f;

    public this(float x2, float y2)
    {
        x = x2;
        y = y2;
    }

    public this(float k)
    {
        x = k;
        y = k;
    }

    public this(vec2 v)
    {
        x = v.x;
        y = v.y;
    }

    public vec2 opBinary(string op : "+")(const vec2 v) const
    {
        return vec2(x + v.x, y + v.y);
    }

    public vec2 opBinary(string op : "-")(const vec2 v) const
    {
        return vec2(x - v.x, y - v.y);
    }

    public float opBinary(string op : "*")(const vec2 v) const
    {
        return x * v.x + y * v.y;
    }

    public vec2 opBinary(string op : "*")(float k) const
    {
        return vec2(k * x, k * y);
    }

    public vec2 opBinary(string op : "/")(float k) const
    {
        return vec2(x / k, y / k);
    }

    public vec2 opBinary(string op : "*")(float k, const vec2 v) const
    {
        return v * k;
    }

    // opOpAssign

    public void opOpAssign(string op : "+")(const vec2 v)
    {
        x += v.x;
        y += v.y;
    }

    public void opOpAssign(string op : "-")(const vec2 v)
    {
        x -= v.x;
        y -= v.y;
    }

    public void opOpAssign(string op : "*")(float k)
    {
        x *= k;
        y *= k;
    }

    public void opOpAssign(string op : "/")(float k)
    {
        x /= k;
        y /= k;
    }

    void opAssign(float k)
    {
        x = k;
        y = k;
    }

    public vec2 opUnary(string op : "-")()
    {
        return vec2(-x, -y);
    }

    public float magnitude() const
    {
        return sqrt(x * x + y * y);
    }

    public void normalize()
    {
        const float mag = magnitude();
        if (mag == 0.0f)
            return;
        (this) /= mag;
    }
}
