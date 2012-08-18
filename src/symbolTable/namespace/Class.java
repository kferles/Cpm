package symbolTable.namespace;

import errorHandling.ErrorMessage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class Class implements DefinesNamespace{
    
    String name;
    
    //TODO: Decide error message, lines etc.
    
    HashMap<String, HashSet<ClassContentElement<? extends Type>>> allSymbols = new HashMap<String, HashSet<ClassContentElement<? extends Type>>>();
    
    HashSet<Class> superClasses = null;
    
    HashMap<String, ClassContentElement<Type>> fields = null;
    
    HashMap<String, ClassContentElement<Class>> innerTypes = null;
    
    /*
     * Methods are represented as a multi map to support method overloading.
     * That is, every name is maped to another map from a signature to a class Method
     * object. 
     */
    HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>> methods = null;
    
    HashSet<String> visibleTypeNames = null;
    
    DefinesNamespace belongsTo;
    
    boolean isComplete;
    
            private class ClassContentElement <T>{
                T element;

                AccessSpecifier access;

                boolean isStatic;

                public ClassContentElement(T element, AccessSpecifier access, boolean isStatic){
                    this.element = element;
                    this.access = access;
                    this.isStatic = isStatic;
                }

                @Override
                public boolean equals(Object o){
                    return this.element.equals(o);
                }

                @Override
                public int hashCode() {
                    return this.element.hashCode();
                }
            }
            
    @Override
    public StringBuilder getStringName(StringBuilder in){
        if(belongsTo == null) return in.append(name);
        return belongsTo.getStringName(in).append("::").append(name);
    }
    
    private boolean isOverrider(String name, Method m) throws ErrorMessage{
        if(this.superClasses == null) return false;
        HashSet<Method> methodsInSuper = new HashSet<Method>();
        collectVirtualsInBases(name, m, new HashSet<Class>(), methodsInSuper);
        for(Method method : methodsInSuper){
            if(m.isOverriderFor(method) == false) throw new ErrorMessage("");
        }
        return true;
    }
    
    private void collectVirtualsInBases(String name, Method m, HashSet<Class> visited, HashSet<Method> res){
        if(visited.contains(this) == true) return;
        visited.add(this);
        if(this.methods != null && this.methods.containsKey(name) == true){
            HashMap<Method.Signature, ClassContentElement<Method>> ms = this.methods.get(name);
            ClassContentElement<Method> supermElem = ms.get(m.getSignature());
            if(supermElem != null){
                Method superm = supermElem.element;
                if(superm.isVirtual() == true) res.add(superm);
            }
        }
        if(this.superClasses != null){
            for(Class t : this.superClasses){
                t.collectVirtualsInBases(name, m, visited, res);
            }
        }
    }
    
    private void insertInAllSymbols(String name, ClassContentElement<? extends Type> entry){
        HashSet<ClassContentElement<? extends Type>> set;
        if(allSymbols.containsKey(name) == true){
            set = allSymbols.get(name);
        }
        else{
            set = new HashSet<ClassContentElement<? extends Type>>();
            allSymbols.put(name, set);
        }
        set.add(entry);
    }
    
    private int searchSuperType(Class t){
        int count = 0;
        if(this.superClasses.contains(t) == true) ++count;
        if(this.superClasses != null){
            for(Class ut : this.superClasses){
                if(ut.equals(t) == false) count += ut.searchSuperType(t);
            }
        }
        return count;
    }
    
    private void addInnerTypesToVisible(HashSet<String> set, HashSet<Class> visited){
        if(visited.contains(this) == true) return;
        visited.add(this);
        if(this.innerTypes != null){
            for(String key : this.innerTypes.keySet()) set.add(key);
        }
        if(this.superClasses != null){
            for(Class t : this.superClasses) t.addInnerTypesToVisible(set, visited);
        }
    }
    
    public enum AccessSpecifier{
        Private, 
        Protected,
        Public
    }
    
    /**
     * Constructs a UserDefinedType according to its name.
     * 
     * @param name Type's name.
     * @param isComplete  whether the type is yet implemented or not.
     * @param belongsTo   The namespace that the type belongs to (either a class or a namespace).
     */
    public Class(String name, DefinesNamespace belongsTo, boolean isComplete){
        this.name = name;
        this.isComplete = isComplete;
        this.belongsTo = belongsTo;
    }
    
    /**
     * Constructs a UserDefinedType that extends some other classes.
     * The ArrayList must contain unique non abstract types so the 
     * constructor will be responsible for no error checking. All these
     * checks must be performed before calling the constructor.
     * @param name          Type's name.
     * @param superTypes    All the super classes.
     * @param belongsTo     The namespace that the type belongs to (either a class or a namespace).
     */
    public Class(String name, DefinesNamespace belongsTo, ArrayList<Class> superTypes){
        this.name = name;
        superClasses = new HashSet<Class>();
        for(Class s : superTypes)
            /*TODO: handle the fields of superclasses 
             *(according to design at most one is allowed to have)
             * also handle methods, fields and inner types.
             */
            superClasses.add(s);
        this.isComplete = true;
        this.belongsTo = belongsTo;
        this.visibleTypeNames = new HashSet<String>();
        this.addInnerTypesToVisible(visibleTypeNames, new HashSet<Class>());
    }
    
    public void setVisibleTypeNames(HashSet<String> set){
        if(this.visibleTypeNames == null) this.visibleTypeNames = new HashSet<String>(set);
        for(String type : set) this.visibleTypeNames.add(type);
    }
    
    /**
     * Insert a field to the current type.
     * 
     * @param name  Field 's name.
     * @param t     A reference to the object that describes field 's type.
     * @return      null if the field is unique inside the Type and an ErrorMessage otherwise.
     */
    public void insertField(String name, Type t, AccessSpecifier access, boolean isStatic) throws ErrorMessage{
        if(fields == null) fields = new HashMap<String, ClassContentElement<Type>>();
        String key = name;      //think how to distinguish field that shadows fields of superclasses.
        if(fields.containsKey(key)) throw new ErrorMessage("");
        if(allSymbols.containsKey(key) == true) throw new ErrorMessage("");
        if(visibleTypeNames.contains(name) == true) throw new ErrorMessage("");
        ClassContentElement<Type> field = new ClassContentElement<Type>(t, access, isStatic);
        fields.put(key, field);
        insertInAllSymbols(key, field);
    }
    
    /**
     * Insert an inner type (i.e nested) to the current type.
     * 
     * @param name Type's name.
     * @param t    A reference to the UserDefinedType object that describes the Type.
     * @return     null if this name is unique inside this scope.
     */
    public void insertInnerType(String name, Class t, AccessSpecifier access, boolean isStatic) throws ErrorMessage{
        if(this.innerTypes == null) this.innerTypes = new HashMap<String, ClassContentElement<Class>>();
        if(name.equals(this.name) == true) throw new ErrorMessage("");
        if(allSymbols.containsKey(name) == true) throw new ErrorMessage("");
        String key = name;
        if(innerTypes.containsKey(key)){
            /*
             * check only if there is another inner type it the same namespace.
             */
            Class t1 = innerTypes.get(key).element;
            if(t1.isComplete == false){
                innerTypes.put(key, new ClassContentElement<Class>(t, access, isStatic));
                return;
            }
            else if(t.isComplete == true){
                throw new ErrorMessage("");
            }
            else{
                return; //check this one with an example.
            }
        }
        this.visibleTypeNames.add(name);
        t.setVisibleTypeNames(this.visibleTypeNames);
        innerTypes.put(key, new ClassContentElement<Class>(t, access, isStatic));
    }
    
    /**
     * Insert a new method to the current type.
     * 
     * @param name  Method's name.
     * @param m     A reference to the Method object that describes the method
     * @return      null if method can be inserted and an ErrorMessage if method cannot be overloaded.
     */
    public void insertMethod(String name, Method m, AccessSpecifier access, boolean isStatic) throws ErrorMessage{
        if(this.methods == null) this.methods = new HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>>();
        if(this.visibleTypeNames.contains(name) == true) throw new ErrorMessage("");
        if(methods.containsKey(name)){
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = methods.get(name);
            if(m1.containsKey(m.getSignature())) throw new ErrorMessage("");
            if(isOverrider(name, m) == true) m.setVirtual();
            m1.put(m.getSignature(), new ClassContentElement<Method>(m, access, isStatic));
        }
        else{
            if(allSymbols.containsKey(name) == true) throw new ErrorMessage("");
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = new HashMap<Method.Signature, ClassContentElement<Method>>();
            ClassContentElement<Method> method = new ClassContentElement<Method>(m, access, isStatic);
            if(isOverrider(name, m) == true) m.setVirtual();
            m1.put(m.getSignature(), method);
            methods.put(name, m1);
            insertInAllSymbols(name, method);
        }
        m.setNamespace(this);
    }
    
    @Override
    public boolean equals(Object o){
        if(o instanceof Class){
            Class ut = (Class) o;
            if(this.belongsTo == ut.belongsTo && this.name.equals(ut.name)) return true;
            return false;
        }
        else return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 67 * hash + (this.name != null ? this.name.hashCode() : 0);
        hash = 67 * hash + (this.belongsTo != null ? this.belongsTo.hashCode() : 0);
        return hash;
    }
    
    public boolean isCovariantWith(Class c) throws ErrorMessage {
        if(c == null) return false;
        if(c.equals(this) == true) return true;
        int baseClassCount = searchSuperType(c);
        if(baseClassCount > 1) throw new ErrorMessage("");  //base class is ambiguous
        if(baseClassCount == 1) return true;
        return false;                                       //types are not converiant
    }
    
    @Override
    public String toString(){
        return this.getStringName(new StringBuilder()).toString();
    }
    
    public boolean isComplete(){
        return this.isComplete;
    }
    
    public String getName(){
        return name;
    }

    
}
