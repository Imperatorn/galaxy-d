module collision;

import core.stdc.math : sqrt;
import core.stdc.wchar_ : wcscpy;
import core.stdc.stdio : puts;
import core.stdc.stdlib : abs;
import core.stdc.math;
import core.stdc.stdlib;

import core.sys.windows.windows;

import std.algorithm.mutation : swap;
import std.stdio : writeln;

import structs;

void Plot(const ref Body b, ref Screen scr)
{
    scr.PlotCircle(b.pos.x, b.pos.y, b.r);
}

float random(float low, float high)
{
    return low + cast(float)(rand()) / (cast(float)(RAND_MAX / (high - low)));
}

enum M_PI = 3.14159265f;

void main()
{
    srand(0);

    auto scr = Screen(0, 0, 5);

    const int n = 20_000;
    enum float dt = 1.0 / 40.0f;

    /* Initializing first galaxy */
    Body Centre1 = Body(2000.0f, 2.5f);
    Centre1.pos = vec2(150.0f, 20.0f);
    Centre1.vel = vec2(-5.0f, 0.0f);

    Body[] Bodies1 = new Body[n];

    for (int i = 0; i < n; i++)
    {
        const float maxRadius = 30.0f; //max radius of the galaxy

        const float theta = random(0.0f, 2 * M_PI); //angle the particle makes with the centre

        float r = random(1.0f, maxRadius);

        r = r * r / maxRadius; //change distribution of particles (optional)
        r += (Centre1.r * 0.2f);
        Bodies1[i].pos = vec2(r * cos(theta), 
                              r * sin(theta)); //polar to cartezian
        Bodies1[i].pos += Centre1.pos; //move the particle relative to the centre

        const float v = sqrt(G * Centre1.m / r); //calculate velocity based on radius
        
        Bodies1[i].vel = vec2(v * sin(theta), 
                             -v * cos(theta)); //polar to cartezian, rotated by 90 degrees
        
        const float offset = 0.6f;
        
        Bodies1[i].vel += vec2(random(-offset, offset), random(-offset, offset)); //random offset to velocity
        Bodies1[i].vel += Centre1.vel;

        Bodies1[i].r = 0.2f;
    }

    /* Initializing second galaxy */
    Body Centre2 = Body(2000.0f, 2.5f);
    Centre2.pos = -Centre1.pos;
    Centre2.vel = -Centre1.vel;

    Body[] Bodies2 = new Body[n];

    for (int i = 0; i < n; i++)
    {
        const float maxRadius = 30.0f;

        const float theta = random(0.0f, 2 * M_PI);

        float r = random(1.0f, maxRadius);
        r = r * r / maxRadius;
        r += Centre2.r * 0.2f;
        Bodies2[i].pos = vec2(r * cos(theta), r * sin(theta));
        Bodies2[i].pos += Centre2.pos;

        const float v = sqrt(G * Centre2.m / r);
        Bodies2[i].vel = vec2(v * sin(theta), -v * cos(theta));
        //uncomment for opposite direction of rotation
        //Bodies2[i].vel = -Bodies2[i].vel;
        const float offset = 0.6f;
        Bodies2[i].vel += vec2(random(-offset, offset), random(-offset, offset));
        Bodies2[i].vel += Centre2.vel;

        Bodies2[i].r = 0.2f;
    }

    while (true)
    {
        scr.Clear();

        //centres attract each other
        Centre1.PulledBy(Centre2);
        Centre2.PulledBy(Centre1);

        //particles are attracted to centres
        for (int i = 0; i < n; i++)
        {
            Bodies1[i].PulledBy(Centre1);
            Bodies2[i].PulledBy(Centre1);
            Bodies1[i].PulledBy(Centre2);
            Bodies2[i].PulledBy(Centre2);
        }

        //update bodies
        Centre1.Update(dt);
        Centre2.Update(dt);
        for (int i = 0; i < n; i++)
            Bodies1[i].Update(dt);
        for (int i = 0; i < n; i++)
            Bodies2[i].Update(dt);

        //rendering
        Plot(Centre1, scr);
        Plot(Centre2, scr);

        for (int i = 0; i < n; i++)
            Plot(Bodies1[i], scr);

        for (int i = 0; i < n; i++)
            Plot(Bodies2[i], scr);

        //drawing
        if ((Centre1.pos - Centre2.pos) * (Centre1.pos - Centre2.pos) < 90.0f * 90.0f)
            scr.Zoom(9);
        
        if ((Centre1.pos - Centre2.pos) * (Centre1.pos - Centre2.pos) > 110.0f * 110.0f)
            scr.Zoom(5);

        scr.Draw();
    }
}
