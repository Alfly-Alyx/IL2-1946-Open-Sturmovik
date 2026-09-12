import java.nio.file.Files;
import java.nio.file.Paths;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import jdk.internal.org.objectweb.asm.*;
import jdk.internal.org.objectweb.asm.tree.*;

/** Executes the real door-switching method in an isolated class with its real fields.
 * Compares the restored fountain method to the trusted 4.09m SFS bytecode.
 */
public final class TestControlsExplosionsNoMds implements Opcodes {
    public static void main(String[] args) throws Exception {
        if(args.length!=3) throw new IllegalArgumentException("cleanControls cleanExplosions stockExplosions");
        ClassNode controls=read(args[0]), explosions=read(args[1]), stock=read(args[2]);
        MethodNode door=find(controls,"setActiveDoor","(I)V");
        ClassNode harness=new ClassNode();
        harness.version=47; harness.access=ACC_PUBLIC; harness.name=controls.name;
        harness.superName="java/lang/Object";
        Set<String> used=new HashSet<String>();
        for(AbstractInsnNode n:door.instructions.toArray()) if(n instanceof FieldInsnNode) used.add(((FieldInsnNode)n).name);
        for(FieldNode f:controls.fields) if(used.contains(f.name)) harness.fields.add(new FieldNode(ACC_PUBLIC,f.name,f.desc,null,null));
        harness.methods.add(door);
        MethodNode ctor=new MethodNode(ACC_PUBLIC,"<init>","()V",null,null);
        ctor.instructions.add(new VarInsnNode(ALOAD,0));
        ctor.instructions.add(new MethodInsnNode(INVOKESPECIAL,"java/lang/Object","<init>","()V",false));
        ctor.instructions.add(new InsnNode(RETURN)); harness.methods.add(ctor);
        ClassWriter writer=new ClassWriter(ClassWriter.COMPUTE_MAXS); harness.accept(writer);
        Class<?> cls=new ByteLoader().load(writer.toByteArray());
        Object obj=cls.getConstructor().newInstance();
        set(cls,obj,"SIDE_DOOR",Integer.valueOf(2));
        set(cls,obj,"cockpitDoor",Float.valueOf(.6F)); set(cls,obj,"cockpitDoorControl",Float.valueOf(.7F));
        set(cls,obj,"fSaveSideDoor",Float.valueOf(.3F)); set(cls,obj,"fSaveSideDoorControl",Float.valueOf(.4F));
        Method switchDoor=cls.getMethod("setActiveDoor",int.class);
        switchDoor.invoke(obj,2);
        check(cls,obj,"bMoveSideDoor",Boolean.TRUE); check(cls,obj,"cockpitDoor",Float.valueOf(.3F));
        check(cls,obj,"cockpitDoorControl",Float.valueOf(.4F)); check(cls,obj,"fSaveCockpitDoor",Float.valueOf(.6F));
        check(cls,obj,"fSaveCockpitDoorControl",Float.valueOf(.7F));
        switchDoor.invoke(obj,2); // Selecting the current door must preserve both positions.
        check(cls,obj,"cockpitDoor",Float.valueOf(.3F)); check(cls,obj,"fSaveCockpitDoor",Float.valueOf(.6F));
        set(cls,obj,"cockpitDoor",Float.valueOf(.8F)); set(cls,obj,"cockpitDoorControl",Float.valueOf(.9F));
        switchDoor.invoke(obj,1);
        check(cls,obj,"bMoveSideDoor",Boolean.FALSE); check(cls,obj,"cockpitDoor",Float.valueOf(.6F));
        check(cls,obj,"cockpitDoorControl",Float.valueOf(.7F)); check(cls,obj,"fSaveSideDoor",Float.valueOf(.8F));
        check(cls,obj,"fSaveSideDoorControl",Float.valueOf(.9F));
        switchDoor.invoke(obj,1);
        check(cls,obj,"cockpitDoor",Float.valueOf(.6F)); check(cls,obj,"fSaveSideDoor",Float.valueOf(.8F));
        switchDoor.invoke(obj,2);
        check(cls,obj,"cockpitDoor",Float.valueOf(.8F)); check(cls,obj,"cockpitDoorControl",Float.valueOf(.9F));
        String descriptor="(Lcom/maddox/JGP/Point3d;FFII)V";
        MethodNode restoredFountain=find(explosions,"fontain",descriptor);
        // The two historical compilers allocated light radius and crater radius
        // to opposite local slots. Normalize that bijection, not the operations.
        for(AbstractInsnNode n:restoredFountain.instructions.toArray()) if(n instanceof VarInsnNode) {
            VarInsnNode v=(VarInsnNode)n;
            if(v.var==9) v.var=10; else if(v.var==10) v.var=9;
        }
        if(!Arrays.equals(canonical(restoredFountain),canonical(find(stock,"fontain",descriptor))))
            throw new AssertionError("Fountain differs from the trusted 4.09m baseline");
        System.out.println("PASS: actual setActiveDoor bytecode, side/cockpit round trip, repeated selection, saved positions");
        System.out.println("PASS: complete fontain method equals trusted 4.09m bytecode after local-slot 9/10 normalization");
    }
    private static void set(Class<?> c,Object o,String f,Object value)throws Exception {c.getField(f).set(o,value);}
    private static void check(Class<?> c,Object o,String f,Object value)throws Exception {
        if(!value.equals(c.getField(f).get(o)))throw new AssertionError("Door state mismatch: "+f);
    }
    private static ClassNode read(String path)throws Exception {ClassNode c=new ClassNode();new ClassReader(Files.readAllBytes(Paths.get(path))).accept(c,ClassReader.SKIP_DEBUG);return c;}
    private static MethodNode find(ClassNode c,String n,String d){for(MethodNode m:c.methods)if(m.name.equals(n)&&m.desc.equals(d))return m;throw new AssertionError(n+d);}
    private static byte[] canonical(MethodNode m) {ClassWriter w=new ClassWriter(ClassWriter.COMPUTE_MAXS);w.visit(47,ACC_PUBLIC,"Canonical",null,"java/lang/Object",null);m.accept(w);w.visitEnd();return w.toByteArray();}
    private static final class ByteLoader extends ClassLoader {Class<?> load(byte[] b){return defineClass(null,b,0,b.length);}}
}
