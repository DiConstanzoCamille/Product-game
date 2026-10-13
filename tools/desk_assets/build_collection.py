"""Original Atelier desk props. Blender 4.3+, no third-party assets.

blender -b --factory-startup --python tools/desk_assets/build_collection.py
Coordinates: Blender Z up, front -Y. glTF exports to Godot Y up, front +Z.
All assets use metres, a floor-level origin, baked bevels and shared PBR materials.
"""
import bpy
import json
import math
import random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/atelier"
OUT.mkdir(parents=True, exist_ok=True)
random.seed(2409)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
M = {}


def material(name, color, roughness=.6, metallic=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = tuple(int(color[i:i+2], 16) / 255 for i in (0, 2, 4))
    # Input art palette is sRGB; Blender shader inputs are scene-linear.
    linear = tuple(v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb)
    m.diffuse_color = (*linear, 1)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*linear, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    M[name] = m
    return m


for args in [
    ("Enamel | pine", "345C56", .32, .12),
    ("Brass | satin", "B99B65", .34, .65),
    ("Charcoal | soft", "29393D", .78, 0),
    ("Ceramic | chalk", "E3DAC4", .37, 0),
    ("Terracotta | clay", "B67555", .82, 0),
    ("Terracotta | edge", "CF9473", .72, 0),
    ("Soil", "3C342A", 1, 0),
    ("Leaf | forest", "38604A", .58, 0),
    ("Leaf | sage", "648568", .62, 0),
    ("Leaf | vein", "91A476", .65, 0),
    ("Leather | teal", "385960", .86, 0),
    ("Linen | rust", "AC7059", .93, 0),
    ("Paper | ivory", "EBE3CD", .95, 0),
    ("Page | shadow", "BEB299", .95, 0),
    ("Oak", "A47B52", .72, 0),
    ("Walnut", "6D4B37", .7, 0),
    ("Graphite", "465158", .54, .15),
    ("Rubber", "20282C", .93, 0),
    ("Silver", "ABB6B5", .28, .7),
    ("Diffuser", "F5E4BF", .68, 0),
]:
    material(*args)


def finish(obj, name, mat, bevel=0):
    obj.name = name
    obj.data.materials.append(M[mat])
    bpy.context.view_layer.objects.active = obj
    if bevel:
        mod = obj.modifiers.new("Manufactured edge", "BEVEL")
        mod.width, mod.segments = bevel, 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def box(name, pos, size, mat, bevel=.002):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    o = bpy.context.object
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, name, mat, min(bevel, min(size) * .42))


def cylinder(name, pos, radius, depth, mat, vertices=48, bevel=.001):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos)
    o = finish(bpy.context.object, name, mat, bevel)
    for p in o.data.polygons:
        p.use_smooth = abs(p.normal.z) < .99
    return o


def tube(name, points, radius, mat, sides=8):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = max(1, sides // 4)
    curve.use_fill_caps = True
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for p, co in zip(spline.points, points):
        p.co = (*co, 1)
    o = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(M[mat])
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target="MESH")
    return bpy.context.object


def lathe(name, profile, mat, count=64, ribs=0):
    # Extra rings keep lighting smooth along tall fluted walls.
    refined = [profile[0]]
    for a, b in zip(profile, profile[1:]):
        steps = max(1, math.ceil(abs(b[1] - a[1]) / .018))
        for step in range(1, steps + 1):
            t = step / steps
            refined.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    profile = refined
    verts, faces = [], []
    for radius, height in profile:
        for i in range(count):
            a = i * math.tau / count
            r = radius + (ribs * (.5 + .5 * math.cos(a * 32)) if radius > .02 else 0)
            verts.append((r * math.cos(a), r * math.sin(a), height))
    for j in range(len(profile)-1):
        for i in range(count):
            n = (i + 1) % count
            faces.append((j*count+i, j*count+n, (j+1)*count+n, (j+1)*count+i))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    finish(o, name, mat)
    for p in mesh.polygons:
        p.use_smooth = True
    return o


def text(name, body, pos, size, mat, rotation=(0, 0, 0)):
    c = bpy.data.curves.new(name, "FONT")
    c.body, c.size, c.extrude = body, size, .00015
    c.align_x, c.align_y = "CENTER", "CENTER"
    c.resolution_u = 3
    o = bpy.data.objects.new(name, c)
    bpy.context.collection.objects.link(o)
    o.location, o.rotation_euler = pos, rotation
    o.data.materials.append(M[mat])
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target="MESH")


def lamp():
    cylinder("Weighted base", (0, 0, .015), .115, .03, "Enamel | pine", bevel=.006)
    cylinder("Brass base inlay", (0, 0, .032), .072, .005, "Brass | satin")
    cylinder("Switch", (.063, -.044, .039), .012, .012, "Charcoal | soft")
    for x in [-.017, .017]:
        tube("Lower parallel arm", [(x, .016, .046), (x, .083, .27)], .007, "Brass | satin")
        tube("Upper parallel arm", [(x, .083, .27), (x, -.072, .48)], .006, "Enamel | pine")
    for y, z in [(.016, .046), (.083, .27), (-.072, .48)]:
        pivot = cylinder("Machined hinge", (0, y, z), .019, .053, "Enamel | pine")
        pivot.rotation_euler.y = math.pi / 2
        for x in [-.029, .029]:
            screw = cylinder("Hinge screw", (x, y, z), .009, .004, "Brass | satin", 24)
            screw.rotation_euler.y = math.pi / 2
    shade = lathe("Spun metal shade", [(0,.038),(.041,.038),(.046,.034),(.052,.015),(.103,-.066),(.106,-.075),(.105,-.080),(.100,-.080),(.098,-.071),(.047,.010),(.040,.028),(0,.028)], "Enamel | pine")
    shade.location = (0, -.11, .492)
    diffuser = cylinder("Warm diffuser", (0, -.11, .414), .097, .003, "Diffuser")
    tube("Braided power cord", [(.02,.012,.055),(.052,.087,.022),(.095,.13,.007),(.16,.13,.007),(.185,.09,.007),(.18,.025,.007)], .003, "Rubber")


def plant():
    lathe("Glazed saucer", [(0,0),(.10,0),(.116,.009),(.116,.019),(.11,.023),(.101,.015),(0,.015)], "Terracotta | edge")
    lathe("Fluted terracotta pot", [(0,.018),(.069,.018),(.075,.027),(.10,.18),(.104,.19),(.103,.198),(.094,.198),(.09,.182),(.065,.035),(0,.035)], "Terracotta | clay", 128, .0015)
    cylinder("Potting soil", (0,0,.18), .091, .009, "Soil")
    for i in range(18):
        a = random.random()*math.tau
        r = random.uniform(.025,.075)
        cylinder("Soil pebble", (r*math.cos(a),r*math.sin(a),.187), random.uniform(.002,.005), .003, "Page | shadow", 8, 0)
    for i in range(11):
        angle = i * 2.39996
        h = .29 + .027*(i%5)
        radial = Vector((math.cos(angle),math.sin(angle),0))
        start = Vector((0,0,.185))
        root = radial*.028 + Vector((0,0,h))
        tube("Leaf stem", [start, radial*.01+Vector((0,0,h-.04)), root], .0024, "Leaf | forest")
        side = Vector((-radial.y,radial.x,0))
        verts=[]
        spine=[]
        length = .15 + .014*(i%3)
        for j in range(13):
            t=j/12
            center=root+radial*length*t+Vector((0,0,.105*math.sin(t*math.pi*.85)-.03*t))
            spine.append(tuple(center+Vector((0,0,.001))))
            width=.039*math.sin(math.pi*t)**.8
            for k in [-1,0,1]:
                verts.append(tuple(center+side*width*k+Vector((0,0,-.012*abs(k)*math.sin(math.pi*t)))))
        faces=[]
        for j in range(12):
            for k in range(2):
                a=j*3+k
                faces.append((a,a+1,a+4,a+3))
        mesh=bpy.data.meshes.new("Curved leaf")
        mesh.from_pydata(verts,[],faces)
        mesh.update()
        o=bpy.data.objects.new("Leaf",mesh)
        bpy.context.collection.objects.link(o)
        finish(o,"Leaf","Leaf | sage" if i%3==0 else "Leaf | forest")
        for p in mesh.polygons:p.use_smooth=True
        mod=o.modifiers.new("Leaf thickness","SOLIDIFY")
        mod.thickness=.001
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.modifier_apply(modifier=mod.name)
        tube("Raised midrib",spine,.00065,"Leaf | vein",4)


def stationery():
    lathe("Ribbed ceramic pencil cup", [(0,0),(.052,0),(.060,.008),(.063,.124),(.061,.132),(.055,.132),(.054,.12),(.047,.012),(0,.012)], "Ceramic | chalk",128,.001)
    cylinder("Cork foot",(0,0,.003),.051,.006,"Oak")
    for i,(x,y,h) in enumerate([(-.027,.01,.19),(-.005,.025,.22),(.020,.005,.185),(.005,-.025,.205)]):
        mat=["Enamel | pine","Linen | rust","Graphite","Brass | satin"][i]
        cylinder("Writing instrument",(x,y,h/2),.004,h,mat,12,.0006)
        cylinder("Pen crown",(x,y,h+.005),.0045,.01,"Brass | satin",16,.0004)
        if i%2==0:
            tube("Pen clip",[(x+.005,y,h-.005),(x+.006,y,h-.035)],.0012,"Brass | satin",4)
    # Two oval scissor grips, readable even from observation distance.
    for x in [-.023,.011]:
        points=[(x+.014*math.cos(a),.033,.195+.025*math.sin(a)) for a in [j*math.tau/32 for j in range(33)]]
        tube("Scissors handle",points,.004,"Charcoal | soft")
        tube("Scissors blade",[(x,.033,.177),(-x*.3,.033,.10)],.0028,"Silver")


def notebooks():
    for i,(width,depth,mat) in enumerate([(.285,.205,"Linen | rust"),(.258,.183,"Leather | teal")]):
        z=.005+i*.038
        box("Cloth lower cover",(0,0,z),(width,depth,.006),mat,.005)
        box("Ivory page block",(.004,0,z+.017),(width-.014,depth-.011,.026),"Paper | ivory",.002)
        box("Cloth upper cover",(0,0,z+.034),(width,depth,.007),mat,.005)
        box("Rounded spine",(-width/2+.006,0,z+.017),(.014,depth,.037),mat,.006)
        for j in range(8):
            box("Page edge",(width/2-.003,0,z+.006+j*.003),(.0007,depth-.015,.00045),"Page | shadow",.0001)
        box("Ribbon bookmark",(.038,-depth/2-.013,z+.012),(.012,.039,.0012),"Brass | satin",.0003)
    box("Elastic closure",(.086,0,.082),(.007,.186,.002),"Charcoal | soft",.0005)
    text("Foil title","FIELD NOTES",(-.022,.025,.0815),.017,"Brass | satin")
    text("Foil edition","PRODUCT / 01",(-.022,-.009,.0815),.009,"Brass | satin")
    for y in [-.06,.064]:
        tube("Cover stitching",[(-.10,y,.0815),(.063,y,.0815)],.00045,"Leaf | vein",4)


def headphones():
    box("Oak stand base",(0,0,.012),(.19,.13,.024),"Oak",.014)
    box("Stand upright",(0,.026,.145),(.025,.025,.26),"Walnut",.005)
    box("Curved headrest",(0,.008,.283),(.10,.058,.018),"Oak",.008)
    # Headband arches in the XZ plane, facing the seated player.
    for y in [-.012,.018]:
        pts=[(.086*math.cos(a),y,.185+.105*math.sin(a)) for a in [j*math.pi/40 for j in range(41)]]
        tube("Headband",pts,.011,"Charcoal | soft")
    pts=[(.080*math.cos(a),.002,.184+.096*math.sin(a)) for a in [j*math.pi/40 for j in range(41)]]
    tube("Leather headband cushion",pts,.009,"Leather | teal")
    for x in [-.083,.083]:
        shell=box("Earcup shell",(x,0,.167),(.041,.075,.101),"Enamel | pine",.018)
        box("Soft ear cushion",(x-math.copysign(.022,x),0,.167),(.015,.065,.084),"Rubber",.006)
        box("Inner fabric",(x-math.copysign(.030,x),0,.167),(.002,.036,.056),"Graphite",.0006)
        pin=cylinder("Brass pivot",(x,-.040,.190),.008,.004,"Brass | satin",24)
        pin.rotation_euler.x=math.pi/2
    tube("Headphone cable",[(.095,0,.117),(.125,-.02,.07),(.14,-.04,.015),(.12,-.073,.007),(.04,-.079,.007)],.002,"Rubber")


def tray():
    box("Walnut valet tray",(0,0,.009),(.22,.13,.018),"Walnut",.008)
    box("Felt liner",(0,0,.019),(.196,.106,.004),"Leather | teal",.008)
    for x in [-.104,.104]:box("Tray rail",(x,0,.026),(.012,.13,.025),"Oak",.005)
    for y in [-.059,.059]:box("Tray rail",(0,y,.026),(.20,.012,.025),"Oak",.005)
    # USB key and a pair of brass paper clips.
    box("USB body",(.043,.009,.027),(.05,.018,.01),"Graphite",.003)
    box("USB connector",(.012,.009,.027),(.016,.012,.005),"Silver",.001)
    for k in range(2):
        x=-.047+k*.028
        pts=[(x+.008*math.cos(a),-.01+.022*math.sin(a),.024+k*.001) for a in [j*math.tau/32 for j in range(33)]]
        tube("Paper clip",pts,.001,"Brass | satin",4)


BUILDERS={"task_lamp":lamp,"rubber_plant":plant,"pencil_cup":stationery,"field_notebooks":notebooks,"headphone_stand":headphones,"valet_tray":tray}
catalog=[]
for name,builder in BUILDERS.items():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    builder()
    # Join each material group: tens of decorative parts become a few draws.
    for mat in M.values():
        objects=[o for o in bpy.context.scene.objects if o.type=="MESH" and o.data.materials and o.data.materials[0]==mat]
        if not objects:continue
        bpy.ops.object.select_all(action="DESELECT")
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        o=bpy.context.object
        o.name=mat.name.replace(" | ","_")
        bpy.context.scene.cursor.location=(0,0,0)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    vertices=sum(len(o.data.vertices) for o in meshes)
    triangles=0
    for o in meshes:
        o.data.calc_loop_triangles()
        triangles+=len(o.data.loop_triangles)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")),export_format="GLB",use_selection=True,export_yup=True,export_cameras=False,export_lights=False,export_animations=False,export_extras=False)
    catalog.append({"asset":name,"meshes":len(meshes),"vertices":vertices,"triangles":triangles,"bytes":(OUT/(name+".glb")).stat().st_size})
(OUT/"catalog.json").write_text(json.dumps({"collection":"Atelier","units":"metres","up":"Y","front":"+Z","origin":"floor","assets":catalog},indent=2)+"\n")
print("ATELIER_ASSETS",json.dumps(catalog))
