#!/usr/bin/env python3
"""Deterministic EDEN//FALL pixel-art and audio asset generator.

Uses only the Python standard library so it can run locally and in GitHub Actions.
All generated assets are original and derived from geometric/procedural rules.
"""
from __future__ import annotations

import argparse
import binascii
import hashlib
import json
import math
import random
import struct
import wave
import zlib
from pathlib import Path
from typing import Iterable, Sequence

SEED = 0xED3F411
SAMPLE_RATE = 22050

RGBA = tuple[int, int, int, int]
Point = tuple[int, int]

PALETTES = {
    "adam": [(14,18,19,255),(57,66,62,255),(224,191,126,255),(247,226,173,255),(95,140,112,255)],
    "abel": [(12,18,20,255),(40,67,69,255),(151,220,205,255),(218,250,239,255),(83,134,151,255)],
    "cain": [(22,12,13,255),(76,32,32,255),(218,91,76,255),(255,169,119,255),(111,71,52,255)],
    "seth": [(12,16,24,255),(42,55,83,255),(122,163,225,255),(210,225,255,255),(88,111,155,255)],
    "naamah": [(20,12,24,255),(65,36,73,255),(195,132,210,255),(241,200,240,255),(107,151,100,255)],
}
ENEMY_PALETTES = {
    "feral": [(20,16,13,255),(80,58,39,255),(170,143,101,255),(228,192,130,255),(104,124,68,255)],
    "outlaw": [(22,14,13,255),(89,43,32,255),(183,103,75,255),(235,164,115,255),(109,83,57,255)],
    "enhanced": [(11,18,18,255),(33,73,69,255),(93,178,158,255),(190,239,210,255),(66,107,121,255)],
    "nephilim": [(18,13,13,255),(64,43,38,255),(115,88,77,255),(184,139,108,255),(150,74,57,255)],
    "fallen": [(14,12,22,255),(52,45,79,255),(116,109,167,255),(199,184,232,255),(119,68,135,255)],
}
BIOME_PALETTES = [
    [(7,12,12,255),(20,36,31,255),(48,78,59,255),(118,156,105,255),(217,207,160,255)],
    [(12,10,9,255),(42,29,24,255),(91,53,38,255),(175,91,54,255),(229,177,101,255)],
    [(7,12,16,255),(18,39,52,255),(38,78,91,255),(86,153,160,255),(192,224,210,255)],
    [(15,10,18,255),(49,29,57,255),(94,51,100,255),(169,91,154,255),(224,176,208,255)],
    [(8,8,12,255),(29,29,43,255),(68,64,94,255),(145,119,173,255),(230,194,134,255)],
]

def clamp(v: float, lo: int=0, hi: int=255) -> int:
    return max(lo, min(hi, int(round(v))))

def mix(a: RGBA, b: RGBA, t: float) -> RGBA:
    return tuple(clamp(a[i] * (1-t) + b[i] * t) for i in range(4))  # type: ignore

class Canvas:
    def __init__(self, w: int, h: int, fill: RGBA=(0,0,0,0)):
        self.w, self.h = w, h
        self.p = bytearray(fill * (w*h))

    def set(self, x: int, y: int, c: RGBA) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y*self.w+x)*4
            if c[3] == 255:
                self.p[i:i+4] = bytes(c)
            elif c[3] > 0:
                oa = self.p[i+3] / 255.0
                na = c[3] / 255.0
                outa = na + oa*(1-na)
                if outa <= 0:
                    return
                for k in range(3):
                    self.p[i+k] = clamp((c[k]*na + self.p[i+k]*oa*(1-na))/outa)
                self.p[i+3] = clamp(outa*255)

    def rect(self, x: int, y: int, w: int, h: int, c: RGBA) -> None:
        for yy in range(y, y+h):
            for xx in range(x, x+w):
                self.set(xx, yy, c)

    def line(self, x0: int, y0: int, x1: int, y1: int, c: RGBA, width: int=1) -> None:
        dx, dy = abs(x1-x0), -abs(y1-y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            r = max(0, width//2)
            self.rect(x0-r, y0-r, width, width, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2*err
            if e2 >= dy:
                err += dy; x0 += sx
            if e2 <= dx:
                err += dx; y0 += sy

    def ellipse(self, cx: int, cy: int, rx: int, ry: int, c: RGBA) -> None:
        if rx <= 0 or ry <= 0:
            return
        for y in range(cy-ry, cy+ry+1):
            yy = (y-cy)/ry
            span = int(rx * math.sqrt(max(0.0, 1.0-yy*yy)))
            for x in range(cx-span, cx+span+1):
                self.set(x, y, c)

    def ring(self, cx: int, cy: int, r: int, c: RGBA, thickness: int=1) -> None:
        for y in range(cy-r-thickness, cy+r+thickness+1):
            for x in range(cx-r-thickness, cx+r+thickness+1):
                d = math.hypot(x-cx, y-cy)
                if r-thickness <= d <= r+thickness:
                    self.set(x,y,c)

    def polygon(self, pts: Sequence[Point], c: RGBA) -> None:
        if len(pts) < 3:
            return
        miny, maxy = min(y for _,y in pts), max(y for _,y in pts)
        for y in range(miny, maxy+1):
            hits = []
            j = len(pts)-1
            for i in range(len(pts)):
                xi, yi = pts[i]; xj, yj = pts[j]
                if (yi > y) != (yj > y):
                    x = xi + (y-yi)*(xj-xi)/(yj-yi)
                    hits.append(int(round(x)))
                j = i
            hits.sort()
            for i in range(0, len(hits)-1, 2):
                for x in range(hits[i], hits[i+1]+1):
                    self.set(x,y,c)

def write_png(path: Path, canvas: Canvas) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = b"".join(b"\x00" + bytes(canvas.p[y*canvas.w*4:(y+1)*canvas.w*4]) for y in range(canvas.h))
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data))+kind+data+struct.pack(">I", binascii.crc32(kind+data)&0xffffffff)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", canvas.w, canvas.h, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(raw, 9))
    payload += chunk(b"IEND", b"")
    path.write_bytes(payload)

def shadow(c: Canvas, cx: int, cy: int, rx: int, ry: int) -> None:
    c.ellipse(cx, cy, rx, ry, (0,0,0,92))

def draw_humanoid_frame(c: Canvas, ox: int, oy: int, pal: list[RGBA], frame: int, state: int, variant: int, enemy=False) -> None:
    bob = [0,1,0,-1,0,1,0,-1][frame%8]
    stride = [0,2,3,2,0,-2,-3,-2][frame%8] if state == 1 else 0
    recoil = [0,2,3,1,0,0,0,0][frame%8] if state == 2 else 0
    lean = [0,1,2,3,2,1,0,-1][frame%8] if state == 3 else 0
    hurt = 2 if state == 4 else 0
    death = min(10, frame*2) if state == 5 else 0
    cx, base = ox+24+lean, oy+40-death
    shadow(c, cx, oy+41, 12, 4)
    leg = pal[1]
    c.line(cx-5, base-12, cx-6-stride, base, leg, 4)
    c.line(cx+5, base-12, cx+6+stride, base, leg, 4)
    c.rect(cx-9-stride, base-2, 7, 3, pal[0])
    c.rect(cx+2+stride, base-2, 7, 3, pal[0])
    body = pal[2] if not hurt else mix(pal[2], (255,255,255,255), 0.65)
    c.polygon([(cx-9,base-27+bob),(cx+8,base-27+bob),(cx+11,base-11),(cx-10,base-11)], body)
    c.rect(cx-7,base-25+bob,14,3,pal[3])
    c.rect(cx-2,base-26+bob,4,15,pal[1])
    c.line(cx-8,base-24+bob,cx-13-stride//2,base-15+bob,pal[2],4)
    c.line(cx+8,base-24+bob,cx+14+recoil,base-20+bob,pal[2],4)
    c.line(cx+12+recoil,base-20+bob,cx+22+recoil,base-20+bob,pal[3],3)
    c.rect(cx+18+recoil,base-22+bob,7,4,pal[0])
    c.ellipse(cx,base-32+bob,7,7,pal[3])
    c.rect(cx-6,base-35+bob,12,5,pal[0])
    c.rect(cx+2,base-33+bob,4,2,pal[4])
    if variant % 5 == 0:
        c.ring(cx,base-32+bob,10,pal[4],1)
    elif variant % 5 == 1:
        c.line(cx-8,base-30,cx-13,base-37,pal[4],2)
        c.line(cx+8,base-30,cx+13,base-37,pal[4],2)
    elif variant % 5 == 2:
        c.rect(cx-11,base-25,3,10,pal[4])
        c.rect(cx+8,base-25,3,10,pal[4])
    elif variant % 5 == 3:
        c.polygon([(cx-13,base-25),(cx-7,base-18),(cx-14,base-13)],pal[4])
        c.polygon([(cx+13,base-25),(cx+7,base-18),(cx+14,base-13)],pal[4])
    else:
        c.ellipse(cx,base-16,4,4,pal[4])
    if enemy:
        c.rect(cx-3,base-34,2,2,(255,74,58,255))
        c.rect(cx+2,base-34,2,2,(255,74,58,255))

def draw_boss_frame(c: Canvas, ox: int, oy: int, pal: list[RGBA], frame: int, state: int, variant: int) -> None:
    cx, cy = ox+48, oy+51
    pulse = [0,1,2,1,0,-1,-2,-1][frame%8]
    rot = frame*math.pi/4 + state*0.3
    shadow(c,cx,oy+84,30,8)
    c.ellipse(cx,cy,25+pulse,27+pulse,pal[1])
    c.ellipse(cx,cy,18,19,pal[2])
    c.ring(cx,cy,31+pulse,pal[3],2)
    for i in range(6):
        a = rot + i*math.tau/6
        x,y = cx+int(math.cos(a)*35),cy+int(math.sin(a)*31)
        c.ellipse(x,y,5,5,pal[4])
        c.line(cx+int(math.cos(a)*24),cy+int(math.sin(a)*22),x,y,pal[1],3)
    c.ellipse(cx,cy,12,7,pal[0])
    c.ellipse(cx+int(math.sin(rot)*4),cy,4,5,(255,190,82,255))
    c.rect(cx-18,cy+23,36,5,pal[0])
    if variant % 2 == 0:
        c.polygon([(cx-24,cy-9),(cx-46,cy-23),(cx-37,cy+10)],pal[2])
        c.polygon([(cx+24,cy-9),(cx+46,cy-23),(cx+37,cy+10)],pal[2])
    else:
        c.line(cx-24,cy-6,cx-44,cy-30,pal[3],6)
        c.line(cx+24,cy-6,cx+44,cy-30,pal[3],6)
        c.line(cx-22,cy+5,cx-45,cy+25,pal[4],5)
        c.line(cx+22,cy+5,cx+45,cy+25,pal[4],5)

def make_character_sheet(path: Path, pal: list[RGBA], variant: int, enemy=False) -> dict:
    frame_w=48; frame_h=48; frames=8; states=6
    sheet=Canvas(frame_w*frames,frame_h*states)
    for st in range(states):
        for fr in range(frames):
            draw_humanoid_frame(sheet,fr*frame_w,st*frame_h,pal,fr,st,variant,enemy)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"frame":[frame_w,frame_h],"frames":frames,
            "rows":{"idle":0,"walk":1,"shoot":2,"dash":3,"hurt":4,"death":5},"fps":[5,10,14,16,10,8]}

def make_boss_sheet(path: Path, pal: list[RGBA], variant: int) -> dict:
    fw=96; fh=96; frames=8; states=4
    sheet=Canvas(fw*frames,fh*states)
    for st in range(states):
        for fr in range(frames):
            draw_boss_frame(sheet,fr*fw,st*fh,pal,fr,st,variant)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"frame":[fw,fh],"frames":frames,
            "rows":{"idle":0,"attack":1,"phase":2,"death":3},"fps":[5,12,8,7]}

def make_weapon_sheet(path: Path, idx: int, pal: list[RGBA]) -> dict:
    fw=32; fh=32; frames=8
    sheet=Canvas(fw*frames,fh)
    for fr in range(frames):
        ox=fr*fw
        flash=max(0,4-abs(2-fr%6))
        angle=(-0.12+0.04*fr)
        x0,y0=ox+6,18
        x1,y1=ox+26,16+int(math.sin(angle)*4)
        sheet.line(x0,y0,x1,y1,pal[2],4)
        sheet.rect(ox+9,19,7,5,pal[1])
        sheet.rect(ox+20,13,8,4,pal[3])
        if flash>1:
            sheet.polygon([(ox+28,15),(ox+31,11),(ox+31,19)],(255,213,101,220))
        if idx%3==0: sheet.ring(ox+13,17,6,pal[4],1)
        elif idx%3==1: sheet.rect(ox+11,8,3,8,pal[4])
        else: sheet.line(ox+8,23,ox+17,25,pal[4],2)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"frame":[fw,fh],"frames":frames,"fps":16}

def make_effect_sheet(path: Path) -> dict:
    names=["muzzle","impact","dash","heal","shield","critical","pickup","death","portal","boss_phase"]
    fw=32; fh=32; frames=8
    sheet=Canvas(fw*frames,fh*len(names))
    for row,name in enumerate(names):
        for fr in range(frames):
            ox,oy=fr*fw,row*fh
            t=fr/(frames-1)
            cx,cy=ox+16,oy+16
            pal=BIOME_PALETTES[row%5]
            if name in ("muzzle","critical"):
                r=2+fr*2
                for i in range(8):
                    a=i*math.tau/8+(0.2*fr)
                    sheet.line(cx,cy,cx+int(math.cos(a)*r),cy+int(math.sin(a)*r),pal[4],2)
            elif name in ("impact","death","boss_phase"):
                r=3+fr*2
                sheet.ring(cx,cy,r,pal[3],2)
                for i in range(6):
                    a=i*math.tau/6
                    sheet.ellipse(cx+int(math.cos(a)*r),cy+int(math.sin(a)*r),2,2,pal[4])
            elif name=="dash":
                sheet.ellipse(cx-int(t*12),cy,12-int(t*6),7-int(t*3),(*pal[3][:3],clamp(220*(1-t))))
            elif name=="heal":
                sheet.rect(cx-3,cy-10+fr,6,20-fr,pal[3])
                sheet.rect(cx-10+fr//2,cy-3,20-fr,6,pal[4])
            elif name=="shield":
                sheet.ring(cx,cy,6+fr,pal[3],2)
            elif name=="pickup":
                sheet.polygon([(cx,cy-10+fr//2),(cx+8,cy),(cx,cy+10-fr//2),(cx-8,cy)],pal[4])
            elif name=="portal":
                sheet.ring(cx,cy,12,pal[2],2)
                sheet.ring(cx,cy,4+(fr%4)*2,pal[4],1)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"frame":[fw,fh],"frames":frames,"rows":{n:i for i,n in enumerate(names)},"fps":18}

def make_item_sheet(path: Path) -> dict:
    ids=["seraph_lens","cherub_coil","bone_orchard","cains_mark","salt_genome","eden_valve","black_manna","industrial_halo","watcher_gland","nephilim_marrow"]
    fw=32; fh=32; frames=4
    sheet=Canvas(fw*frames,fh*len(ids))
    for row,item in enumerate(ids):
        pal=BIOME_PALETTES[row%5]
        for fr in range(frames):
            ox,oy=fr*fw,row*fh
            bob=[0,-1,0,1][fr]
            cx,cy=ox+16,oy+16+bob
            sheet.ring(cx,cy,11,pal[1],2)
            if row==0:
                sheet.ellipse(cx,cy,8,5,pal[3]); sheet.ellipse(cx,cy,3,4,pal[4])
            elif row==1:
                for i in range(5): sheet.ring(cx,cy,3+i*2,pal[2],1)
            elif row==2:
                sheet.ellipse(cx,cy,7,10,pal[3]); sheet.line(cx,cy-7,cx,cy+7,pal[0],2)
            elif row==3:
                sheet.polygon([(cx,cy-10),(cx+9,cy+8),(cx,cy+3),(cx-9,cy+8)],pal[3])
            elif row==4:
                for i in range(5): sheet.ellipse(cx-8+i*4,cy,2,6,pal[4])
            elif row==5:
                sheet.rect(cx-8,cy-8,16,16,pal[2]); sheet.rect(cx-3,cy-11,6,22,pal[4])
            elif row==6:
                sheet.ellipse(cx,cy,8,10,(30,23,42,255)); sheet.ring(cx,cy,9,pal[4],1)
            elif row==7:
                sheet.ring(cx,cy,10,pal[4],2); sheet.ring(cx,cy,5,pal[2],1)
            elif row==8:
                sheet.ellipse(cx,cy,9,6,pal[3]); sheet.ellipse(cx,cy,3,4,(255,92,154,255))
            else:
                sheet.rect(cx-7,cy-10,14,20,pal[2]); sheet.line(cx-7,cy,cx+7,cy,pal[4],2)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"frame":[fw,fh],"frames":frames,"rows":{n:i for i,n in enumerate(ids)},"fps":6}

def make_tileset(path: Path, index: int) -> dict:
    pal=BIOME_PALETTES[index]
    tile=32; cols=8; rows=4
    sheet=Canvas(tile*cols,tile*rows)
    rng=random.Random(SEED+index*991)
    for r in range(rows):
        for col in range(cols):
            ox,oy=col*tile,r*tile
            sheet.rect(ox,oy,tile,tile,pal[0])
            for y in range(tile):
                for x in range(tile):
                    n=rng.random()
                    if n<0.12:
                        sheet.set(ox+x,oy+y,pal[1])
                    elif n<0.135:
                        sheet.set(ox+x,oy+y,pal[2])
            sheet.line(ox,oy+tile-1,ox+tile-1,oy+tile-1,pal[2],1)
            sheet.line(ox+tile-1,oy,ox+tile-1,oy+tile-1,pal[1],1)
            motif=(col+r*3)%5
            if motif==0: sheet.ring(ox+16,oy+16,7,pal[2],1)
            elif motif==1:
                sheet.line(ox+4,oy+8,ox+27,oy+23,pal[2],2)
                sheet.line(ox+4,oy+24,ox+27,oy+9,pal[1],1)
            elif motif==2:
                for i in range(4): sheet.ellipse(ox+7+i*6,oy+16,2,5,pal[2])
            elif motif==3: sheet.rect(ox+7,oy+7,18,18,(*pal[2][:3],120))
            else:
                sheet.line(ox+16,oy+4,ox+16,oy+27,pal[2],2)
                sheet.line(ox+4,oy+16,ox+27,oy+16,pal[1],1)
    write_png(path,sheet)
    return {"path":str(path.as_posix()),"tile":[tile,tile],"columns":cols,"rows":rows}

def make_boot_splash(path: Path) -> None:
    w,h=1280,720
    c=Canvas(w,h,(7,11,12,255))
    for y in range(h):
        t=y/(h-1)
        col=mix((7,11,12,255),(20,39,32,255),t*0.7)
        c.rect(0,y,w,1,col)
    cx,cy=w//2,h//2-30
    for r,col in [(185,(58,94,75,255)),(142,(94,137,104,255)),(96,(204,187,126,255))]:
        c.ring(cx,cy,r,col,3)
    c.ellipse(cx,cy,55,55,(28,61,49,255))
    c.ellipse(cx,cy,31,31,(144,190,121,255))
    c.line(cx,cy-140,cx,cy+140,(202,207,171,255),3)
    c.rect(cx-260,cy+215,520,5,(220,206,161,255))
    c.rect(cx-160,cy+235,320,2,(102,139,118,255))
    write_png(path,c)

def waveform_sample(kind: str, phase: float) -> float:
    if kind=="sine": return math.sin(phase)
    if kind=="square": return 1.0 if math.sin(phase)>=0 else -1.0
    if kind=="tri": return 2.0/math.pi*math.asin(math.sin(phase))
    if kind=="saw": return 2.0*((phase/(2*math.pi))%1.0)-1.0
    return math.sin(phase)

def note_freq(midi: float) -> float:
    return 440.0*(2.0**((midi-69.0)/12.0))

def write_wav(path: Path, samples: Iterable[float], sr: int=SAMPLE_RATE) -> None:
    path.parent.mkdir(parents=True,exist_ok=True)
    data=bytearray()
    for s in samples:
        data += struct.pack("<h", clamp(s*32767,-32768,32767))
    with wave.open(str(path),"wb") as wf:
        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(sr); wf.writeframes(data)

def adsr(t: float, dur: float, a=.02, d=.08, s=.65, r=.12) -> float:
    if t<0 or t>dur: return 0.0
    if t<a: return t/max(a,1e-6)
    if t<a+d: return 1-(1-s)*(t-a)/d
    if t<dur-r: return s
    return s*max(0,(dur-t)/max(r,1e-6))

def music_loop(index: int, seconds: float=24.0) -> list[float]:
    sr=SAMPLE_RATE; n=int(seconds*sr)
    out=[0.0]*n
    rng=random.Random(SEED+1000+index)
    bpm=[82,96,74,108,68][index]
    beat=60/bpm
    roots=[45,38,50,43,34]
    scales=[[0,2,3,7,10],[0,1,5,7,8],[0,3,5,7,10],[0,2,5,8,10],[0,1,4,7,11]]
    waveforms=["tri","saw","sine","square","tri"]
    root=roots[index]; scale=scales[index]
    for i in range(n):
        t=i/sr
        f=note_freq(root-12)
        out[i]+=0.12*math.sin(2*math.pi*f*t)+0.05*math.sin(2*math.pi*f*1.5*t)
    steps=int(seconds/(beat/2))
    for step in range(steps):
        start=step*beat/2
        degree=scale[(step*3+index+(step//8))%len(scale)]
        if rng.random()<0.2: degree=scale[rng.randrange(len(scale))]
        midi=root+degree+(12 if step%16 in (7,15) else 0)
        dur=beat*0.48
        bass_midi=root-12+scale[(step//4)%len(scale)]
        for voice,vmidi,amp,wavekind in [(0,midi,0.20,waveforms[index]),(1,bass_midi,0.16,"sine")]:
            st=start if voice==0 else (step//2)*beat
            vd=dur if voice==0 else beat*0.9
            if voice==1 and step%2: continue
            a0=int(st*sr); a1=min(n,int((st+vd)*sr))
            freq=note_freq(vmidi)
            for i in range(a0,a1):
                tt=i/sr-st
                vibr=1+0.003*math.sin(2*math.pi*5.2*tt)
                out[i]+=amp*adsr(tt,vd)*waveform_sample(wavekind,2*math.pi*freq*vibr*tt)
    for beat_i in range(int(seconds/beat)):
        for sub,kind in [(0,"kick"),(0.5,"hat")]:
            st=(beat_i+sub)*beat
            length=.16 if kind=="kick" else .06
            a0=int(st*sr); a1=min(n,int((st+length)*sr))
            for i in range(a0,a1):
                tt=i/sr-st
                env=math.exp(-tt*(22 if kind=="kick" else 50))
                if kind=="kick":
                    ph=2*math.pi*(92-50*tt)*tt
                    out[i]+=0.28*env*math.sin(ph)
                else:
                    noise=rng.uniform(-1,1)
                    out[i]+=0.08*env*noise
    fade=int(.06*sr)
    for i,v in enumerate(out):
        g=1.0
        if i<fade: g=i/fade
        if i>=n-fade: g=(n-i-1)/fade
        out[i]=math.tanh(v*1.15)*0.72*g
    return out

def ambience(index: int, seconds: float=18.0) -> list[float]:
    rng=random.Random(SEED+2000+index)
    n=int(seconds*SAMPLE_RATE); out=[]
    prev=0.0
    f=[47,61,39,73,31][index]
    for i in range(n):
        t=i/SAMPLE_RATE
        noise=rng.uniform(-1,1)
        prev=prev*0.985+noise*0.015
        pulse=0.5+0.5*math.sin(2*math.pi*(0.07+index*0.01)*t)
        s=0.10*prev+0.045*math.sin(2*math.pi*f*t)+0.025*pulse*math.sin(2*math.pi*f*1.5*t)
        edge=min(1,i/(SAMPLE_RATE*.08),(n-i-1)/(SAMPLE_RATE*.08))
        out.append(s*max(0,edge))
    return out

def make_sfx(name: str, variant: int=0) -> list[float]:
    rng=random.Random(SEED+3000+sum(map(ord,name))+variant*17)
    durations={"shot":.14,"enemy_shot":.18,"dash":.25,"impact":.13,"hurt":.32,"kill":.38,
               "pickup":.32,"relic":.65,"shield":.46,"door":.62,"boss_phase":1.2,
               "death":1.25,"victory":1.7,"ui":.12,"shop":.48,"heal":.55,"critical":.22,"portal":.9}
    base=name.split("_")[0]
    dur=durations.get(base,durations.get(name,.35))
    n=int(dur*SAMPLE_RATE); out=[]
    for i in range(n):
        t=i/SAMPLE_RATE; q=t/dur
        env=(1-q)**(1.5 if base in ("shot","impact","ui") else .8)
        noise=rng.uniform(-1,1)
        if base=="shot":
            f=720-420*q+variant*45; s=.52*math.sin(2*math.pi*f*t)+.16*noise
        elif name=="enemy_shot":
            f=390-140*q; s=.44*waveform_sample("saw",2*math.pi*f*t)+.12*noise
        elif base=="dash":
            f=180+1100*q; s=.34*math.sin(2*math.pi*f*t)+.22*noise*(1-q)
        elif base=="impact":
            f=110+variant*25; s=.34*math.sin(2*math.pi*f*t)+.30*noise
        elif base in ("hurt","kill","death"):
            f=230*(1-q)+55; s=.38*waveform_sample("saw",2*math.pi*f*t)+.18*noise
        elif base in ("pickup","relic","heal","victory","shop"):
            f=note_freq(60+variant*2+int(q*12)); s=.33*math.sin(2*math.pi*f*t)+.14*math.sin(2*math.pi*f*2*t)
        elif base=="shield":
            f=480+220*math.sin(q*math.pi); s=.32*math.sin(2*math.pi*f*t)+.14*math.sin(2*math.pi*f*1.5*t)
        elif base=="door":
            f=70+50*q; s=.26*waveform_sample("square",2*math.pi*f*t)+.18*noise
        elif base=="boss":
            f=55+90*q; s=.36*math.sin(2*math.pi*f*t)+.22*waveform_sample("saw",2*math.pi*f*.5*t)
        elif base=="critical":
            f=950-300*q; s=.42*math.sin(2*math.pi*f*t)+.18*noise
        elif base=="portal":
            f=180+70*math.sin(q*math.tau*3); s=.28*math.sin(2*math.pi*f*t)+.18*math.sin(2*math.pi*f*1.618*t)
        else:
            f=520; s=.3*math.sin(2*math.pi*f*t)
        out.append(math.tanh(s*1.5)*env*.75)
    return out

def generate(out_dir: Path) -> dict:
    out_dir.mkdir(parents=True,exist_ok=True)
    manifest={"version":1,"seed":SEED,"players":{},"enemies":{},"bosses":{},"weapons":{},"effects":{},"items":{},"tiles":{},"music":{},"ambience":{},"sfx":{}}
    for i,(name,pal) in enumerate(PALETTES.items()):
        rel=Path("players")/f"{name}.png"
        manifest["players"][name]=make_character_sheet(out_dir/rel,pal,i,False)
        manifest["players"][name]["path"]="res://assets/generated/"+rel.as_posix()
    categories=list(ENEMY_PALETTES)
    for ci,cat in enumerate(categories):
        manifest["enemies"][cat]=[]
        for v in range(5):
            rel=Path("enemies")/f"{cat}_{v+1:02d}.png"
            entry=make_character_sheet(out_dir/rel,ENEMY_PALETTES[cat],v+ci*5,True)
            entry["path"]="res://assets/generated/"+rel.as_posix()
            manifest["enemies"][cat].append(entry)
    boss_names=["watcher_engine","seraph_reactor","nephilim_king","eden_warden","void_archon"]
    for i,name in enumerate(boss_names):
        pal=BIOME_PALETTES[i]
        rel=Path("bosses")/f"{name}.png"
        entry=make_boss_sheet(out_dir/rel,pal,i)
        entry["path"]="res://assets/generated/"+rel.as_posix()
        manifest["bosses"][name]=entry
    weapon_names=["genesis_rifle","tithe_pistol","mark_cannon","continuation_lance","spore_repeater","seraph_beam","salt_shotgun","watcher_carbine","marrow_launcher","eden_arc"]
    for i,name in enumerate(weapon_names):
        pal=list(PALETTES.values())[i%5]
        rel=Path("weapons")/f"{name}.png"
        entry=make_weapon_sheet(out_dir/rel,i,pal)
        entry["path"]="res://assets/generated/"+rel.as_posix()
        manifest["weapons"][name]=entry
    rel=Path("effects")/"effects.png"; manifest["effects"]=make_effect_sheet(out_dir/rel); manifest["effects"]["path"]="res://assets/generated/"+rel.as_posix()
    rel=Path("items")/"relics.png"; manifest["items"]=make_item_sheet(out_dir/rel); manifest["items"]["path"]="res://assets/generated/"+rel.as_posix()
    for i in range(5):
        rel=Path("tiles")/f"biome_{i+1:02d}.png"
        entry=make_tileset(out_dir/rel,i); entry["path"]="res://assets/generated/"+rel.as_posix()
        manifest["tiles"][f"biome_{i+1}"]=entry
    make_boot_splash(out_dir/"ui"/"boot_splash.png")
    for i in range(5):
        name=f"biome_{i+1:02d}"
        rel=Path("audio")/"music"/f"{name}.wav"; write_wav(out_dir/rel,music_loop(i))
        manifest["music"][name]="res://assets/generated/"+rel.as_posix()
        rel=Path("audio")/"ambience"/f"{name}.wav"; write_wav(out_dir/rel,ambience(i))
        manifest["ambience"][name]="res://assets/generated/"+rel.as_posix()
    sfx_names=["shot_01","shot_02","shot_03","enemy_shot","dash","impact_01","impact_02","hurt","kill",
               "pickup","relic","shield","door","boss_phase","death","victory","ui","shop","heal","critical","portal"]
    for i,name in enumerate(sfx_names):
        rel=Path("audio")/"sfx"/f"{name}.wav"; write_wav(out_dir/rel,make_sfx(name,i%3))
        manifest["sfx"][name]="res://assets/generated/"+rel.as_posix()
    files=[]
    for p in sorted(out_dir.rglob("*")):
        if p.is_file():
            files.append({"path":p.relative_to(out_dir).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"bytes":p.stat().st_size})
    manifest["files"]=files
    (out_dir/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
    license_text="""EDEN//FALL GENERATED ASSET PACK
Copyright (c) 2026 Gameish contributors.

All images, animation frames, music, ambience and sound effects in this directory
were generated from original procedural geometry and synthesis code in
tools/generate_assets.py. No third-party artwork, samples or recordings are used.
"""
    (out_dir/"ASSET_NOTICE.txt").write_text(license_text,encoding="utf-8")
    return manifest

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",default="assets/generated")
    args=ap.parse_args()
    manifest=generate(Path(args.out))
    print(f"Generated {len(manifest['files'])} assets in {args.out}")

if __name__=="__main__":
    main()
