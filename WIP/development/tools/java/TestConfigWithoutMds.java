import java.nio.file.Files;
import java.nio.file.Paths;
import java.lang.reflect.Method;
import java.util.*;
import jdk.internal.org.objectweb.asm.*;
import jdk.internal.org.objectweb.asm.tree.*;
import jdk.internal.org.objectweb.asm.tree.analysis.*;

/** Executes the real Config constructor/loadNet/saveNet with in-memory dependencies.
 * Native initialization is isolated; no files, sockets or game process are opened.
 */
public final class TestConfigWithoutMds implements Opcodes {
    private static final String CONFIG="com/maddox/il2/engine/Config";
    private static final Map<String,String> REMAP=new HashMap<String,String>();
    static {
        REMAP.put("com/maddox/rts/IniFile","TestConfigWithoutMds$IniFile");
        REMAP.put("com/maddox/rts/NetChannel","TestConfigWithoutMds$NetChannel");
        REMAP.put("com/maddox/rts/net/SocksUdpSocket","TestConfigWithoutMds$SocksUdpSocket");
        REMAP.put("com/maddox/util/UnicodeTo8bit","TestConfigWithoutMds$UnicodeTo8bit");
        REMAP.put("com/maddox/il2/engine/GObj","TestConfigWithoutMds$GObj");
    }
    public static void main(String[] args) throws Exception {
        if(args.length!=2)throw new IllegalArgumentException("candidateConfig stockConfig");
        byte[] candidate=Files.readAllBytes(Paths.get(args[0]));
        byte[] stock=Files.readAllBytes(Paths.get(args[1]));
        ClassNode parsed=parse(candidate);
        require(!new String(candidate,java.nio.charset.StandardCharsets.ISO_8859_1).toLowerCase(Locale.ROOT).contains("zuti"),"Residual MDS constant");
        checkSelfReferences(parsed);
        for(MethodNode m:parsed.methods)if((m.access&(ACC_NATIVE|ACC_ABSTRACT))==0)new Analyzer<BasicValue>(new BasicVerifier()).analyze(parsed.name,m);
        for(boolean render:new boolean[]{false,true})for(boolean proxy:new boolean[]{false,true}) {
            Map<String,Object> observed=exercise(candidate,render,proxy,true);
            Map<String,Object> baseline=exercise(stock,render,proxy,false);
            require(observed.equals(baseline),"Network behavior differs from stock: render="+render+",proxy="+proxy+"\n"+observed+"\n"+baseline);
        }
        System.out.println("PASS Config: constructor defaults/branding; real loadNet/saveNet bytecode in 4 render/proxy scenarios equals stock");
        System.out.println("PASS Config: normal network options retained; MDS history untouched and never accessed; all self references resolve; ASM verification");
    }
    private static Map<String,Object> exercise(byte[] bytes,boolean render,boolean proxy,boolean branded)throws Exception {
        ClassNode source=parse(bytes), harness=new ClassNode();
        harness.version=source.version;harness.access=ACC_PUBLIC;harness.name=CONFIG;harness.superName="java/lang/Object";
        Set<String> selected=new HashSet<String>(Arrays.asList("<init>","loadNet","saveNet","isUSE_RENDER"));
        for(MethodNode m:source.methods)if(selected.contains(m.name))harness.methods.add(m);
        Set<String> fields=new HashSet<String>();
        for(MethodNode m:harness.methods)for(AbstractInsnNode n:m.instructions.toArray())if(n instanceof FieldInsnNode&&((FieldInsnNode)n).owner.equals(CONFIG))fields.add(((FieldInsnNode)n).name);
        for(FieldNode f:source.fields)if(fields.contains(f.name))harness.fields.add(new FieldNode((f.access&ACC_STATIC)|ACC_PUBLIC,f.name,remap(f.desc),null,f.value));
        // Config.load normally initializes rendering and native engine state.
        // It is replaced only inside this ephemeral test class. The actual
        // constructor remains otherwise intact, including every field default.
        MethodNode isolatedLoad=new MethodNode(ACC_PUBLIC,"load","()V",null,null);
        isolatedLoad.instructions.add(new InsnNode(RETURN));harness.methods.add(isolatedLoad);
        for(MethodNode m:harness.methods) {
            m.desc=remap(m.desc);
            for(AbstractInsnNode n:m.instructions.toArray()) {
                if(n instanceof MethodInsnNode){MethodInsnNode x=(MethodInsnNode)n;x.owner=remap(x.owner);x.desc=remap(x.desc);}
                if(n instanceof FieldInsnNode){FieldInsnNode x=(FieldInsnNode)n;x.owner=remap(x.owner);x.desc=remap(x.desc);}
                if(n instanceof TypeInsnNode){TypeInsnNode x=(TypeInsnNode)n;x.desc=remap(x.desc);}
            }
        }
        ClassWriter w=new ClassWriter(ClassWriter.COMPUTE_MAXS);harness.accept(w);
        Class<?> cls=new ByteLoader().load(w.toByteArray());
        IniFile ini=new IniFile();
        ini.values.put("remoteHost_000","existing-history-entry");
        ini.values.put("localPort","31000");ini.values.put("remotePort","32000");ini.values.put("speed","20000");
        ini.values.put("remoteHost","test.invalid");ini.values.put("routeChannels","4");ini.values.put("serverChannels","42");
        ini.values.put("SkinDownload","0");ini.values.put("serverName","Test Server");ini.values.put("serverDescription","Description");
        ini.values.put("checkServerTimeSpeed","0");ini.values.put("checkClientTimeSpeed","1");
        ini.values.put("checkTimeSpeedDifferense","0.5");ini.values.put("checkTimeSpeedInterval","4");
        if(proxy){ini.values.put("socksHost","proxy.invalid");ini.values.put("socksPort","1099");ini.values.put("socksUser","test-user");ini.values.put("socksPwd","test-password");}
        Object instance=cls.getConstructor(IniFile.class,boolean.class).newInstance(ini,render);
        if(branded)require("Open Sturmovik".equals(cls.getField("windowTitle").get(instance)),"Constructor branding lost");
        Method load=cls.getDeclaredMethod("loadNet"),save=cls.getDeclaredMethod("saveNet");load.setAccessible(true);save.setAccessible(true);
        SocksUdpSocket.reset();NetChannel.reset();load.invoke(instance);
        Map<String,Object> result=new TreeMap<String,Object>();
        for(java.lang.reflect.Field f:cls.getFields())if(f.getName().startsWith("net"))result.put(f.getName(),f.get(instance));
        require(Integer.valueOf(render?31:42).equals(result.get("netServerChannels")),"Render-dependent channel cap changed");
        require(Integer.valueOf(31000).equals(result.get("netLocalPort")),"Local port changed");
        require(Integer.valueOf(20000).equals(result.get("netSpeed")),"Network speed changed");
        require(Boolean.FALSE.equals(result.get("netSkinDownload")),"Skin-download option changed");
        require("Test Server".equals(result.get("netServerName")),"Server name changed");
        save.invoke(instance);
        require("existing-history-entry".equals(ini.values.get("remoteHost_000")),"Existing history value was modified");
        for(String key:ini.accessed)require(!key.startsWith("remoteHost_"),"Removed history key was accessed");
        result.put("ini",new TreeMap<String,String>(ini.values));result.put("accessed",new ArrayList<String>(ini.accessed));
        result.put("checkServerTimeSpeed",NetChannel.bCheckServerTimeSpeed);result.put("checkClientTimeSpeed",NetChannel.bCheckClientTimeSpeed);
        result.put("checkTimeSpeedDifferense",NetChannel.checkTimeSpeedDifferense);result.put("checkTimeSpeedInterval",NetChannel.checkTimeSpeedInterval);
        return result;
    }
    private static void checkSelfReferences(ClassNode c) {
        Set<String> fields=new HashSet<String>(),methods=new HashSet<String>();
        for(FieldNode f:c.fields)fields.add(f.name+f.desc);for(MethodNode m:c.methods)methods.add(m.name+m.desc);
        for(MethodNode m:c.methods)for(AbstractInsnNode n:m.instructions.toArray()) {
            if(n instanceof FieldInsnNode){FieldInsnNode f=(FieldInsnNode)n;if(f.owner.equals(CONFIG))require(fields.contains(f.name+f.desc),"Missing own field "+f.name);}
            if(n instanceof MethodInsnNode){MethodInsnNode call=(MethodInsnNode)n;if(call.owner.equals(CONFIG))require(methods.contains(call.name+call.desc),"Missing own method "+call.name);}
        }
        MethodNode context=null;for(MethodNode m:c.methods)if(m.name.equals("createGlContext")&&m.desc.startsWith("(Ljava/lang/String;)"))context=m;
        require(context!=null,"Missing window creation");int brands=0;
        for(AbstractInsnNode n:context.instructions.toArray())if(n instanceof FieldInsnNode) {
            FieldInsnNode f=(FieldInsnNode)n;
            if(f.owner.equals(CONFIG)&&f.name.equals("windowTitle")&&f.getOpcode()==PUTFIELD) {
                AbstractInsnNode previous=n.getPrevious();while(previous.getOpcode()<0)previous=previous.getPrevious();
                require(previous instanceof LdcInsnNode&&"Open Sturmovik".equals(((LdcInsnNode)previous).cst),"Effective branding changed");brands++;
            }
        }
        require(brands==1,"Unexpected title assignments");
    }
    private static String remap(String s){for(Map.Entry<String,String> e:REMAP.entrySet())s=s.replace(e.getKey(),e.getValue());return s;}
    private static ClassNode parse(byte[] b){ClassNode c=new ClassNode();new ClassReader(b).accept(c,ClassReader.SKIP_DEBUG);return c;}
    private static void require(boolean c,String m){if(!c)throw new AssertionError(m);}
    private static final class ByteLoader extends ClassLoader {Class<?> load(byte[] b){return defineClass(null,b,0,b.length);}}
    public static final class GObj {public static void loadNative(){}}
    public static final class UnicodeTo8bit {public static String load(String s){return s;}public static String save(String s,boolean b){return s;}}
    public static final class NetChannel {
        public static boolean bCheckServerTimeSpeed,bCheckClientTimeSpeed;public static double checkTimeSpeedDifferense;public static int checkTimeSpeedInterval;
        static void reset(){bCheckServerTimeSpeed=true;bCheckClientTimeSpeed=false;checkTimeSpeedDifferense=.2;checkTimeSpeedInterval=10;}
    }
    public static final class SocksUdpSocket {
        private static String host,user,password;private static int port;
        public static void setProxyHost(String s){host=s;}public static String getProxyHost(){return host;}
        public static void setProxyUser(String s){user=s;}public static String getProxyUser(){return user;}
        public static void setProxyPassword(String s){password=s;}public static String getProxyPassword(){return password;}
        public static void setProxyPort(int p){port=p;}public static int getProxyPort(){return port;}
        static void reset(){host=null;user=null;password=null;port=1080;}
    }
    public static final class IniFile {
        final Map<String,String> values=new TreeMap<String,String>();final List<String> accessed=new ArrayList<String>();
        public String get(String section,String key,String fallback){accessed.add(key);return values.containsKey(key)?values.get(key):fallback;}
        public int get(String section,String key,int fallback){String v=get(section,key,(String)null);return v==null?fallback:Integer.parseInt(v);}
        public int get(String section,String key,int fallback,int min,int max){return Math.max(min,Math.min(max,get(section,key,fallback)));}
        public float get(String section,String key,float fallback,float min,float max){String v=get(section,key,(String)null);return Math.max(min,Math.min(max,v==null?fallback:Float.parseFloat(v)));}
        public boolean get(String section,String key,boolean fallback){String v=get(section,key,(String)null);return v==null?fallback:!v.equals("0");}
        public boolean setValue(String section,String key,String value){accessed.add(key);values.put(key,value);return true;}
        public void deleteValue(String section,String key){accessed.add(key);values.remove(key);}
    }
}
