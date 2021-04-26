module threebody;
import std;
import core.thread.osthread;

import structs;

enum n = 6;
enum float dt = 1.0 / 100.0f;

Body[n] solarSystem;

void main()
{
    float limit = 2.0f;

    int prevZoom = 100;
    int zoomlevel = 100;
    auto scr = Screen(0, 0, 200);

    setBodies();

    while (true)
    {
        scr.Clear();

        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++)
                if (i != j)
                    solarSystem[j].PulledBy(solarSystem[i]);

        for (int i = 0; i < n; i++)
            solarSystem[i].Update(dt);

        for (int i = 0; i < n; i++)
            Plot(solarSystem[i], scr);

        scr.Draw();

        float maxX = 0, maxY = 0;

        foreach (ref Body b; solarSystem)
        {
            maxX = b.pos.x > maxX ? b.pos.x : maxX;
            maxY = b.pos.y > maxY ? b.pos.y : maxY;
        }

        if (abs(maxX) >= limit || abs(maxY) >= limit)
        {
            if (zoomlevel > 30)
            {
                zoomlevel -= limit;
                increaseRadius(1.0 / zoomlevel);
                limit += 3;
            }
            //Reset
        else if (abs(maxX) >= 50 || abs(maxY) >= 50)
            {
                zoomlevel = 100;
                prevZoom = 100;
                limit = 3;
                scr.Zoom(zoomlevel);
                setBodies();
            }
        }

        if (zoomlevel != prevZoom)
        {
            scr.Zoom(zoomlevel);
            prevZoom = zoomlevel;
        }

        printf("%f %f", abs(maxX), abs(maxY), zoomlevel);
        Thread.sleep(dur!"msecs"(25));
    }
}

void setBodies()
{
    auto rnd = MinstdRand0(uniform(1, 1000));
    auto rnd2 = MinstdRand0(uniform(1, 1000));

    for (int i = 0; i < n; i++)
    {
        float x = 2 * uniform01(rnd) - 3 * uniform01(rnd2);
        float y = 3 * uniform01(rnd2) - 2 * uniform01(rnd);

        float vx = 0.01;
        float vy = 0.01;

        solarSystem[i].pos = vec2(x, y);
        solarSystem[i].vel = vec2(vx, vy);
        solarSystem[i].m = 2.0f;
        solarSystem[i].r = 0.3f;
    }
}

void increaseRadius(float factor)
{
    for (int i = 0; i < n; i++)
    {
        solarSystem[i].r += factor;
    }
}

void Plot(const ref Body b2, ref Screen scr)
{
    vec2 O = b2.pos;
    vec2 X = b2.pos + b2.vel * 0.5f;

    scr.PlotCircle(b2.pos.x, b2.pos.y, b2.r);
    scr.PlotLine(O.x, O.y, X.x, X.y);

    vec2 a = (O - X);
    a.normalize();
    a *= 0.1f;
    vec2 b = vec2(a.y, -a.x);

    scr.PlotLine(X.x, X.y, X.x + a.x + b.x, X.y + a.y + b.y);
    scr.PlotLine(X.x, X.y, X.x + a.x - b.x, X.y + a.y - b.y);
}
