package symbolTable.types;

import errorHandling.ErrorMessage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import symbolTable.DefinesNamespace;
import symbolTable.types.Method.Signature;

/**
 *
 * @author kostas
 */
public class UserDefinedType extends SimpleType implements DefinesNamespace{
    //TODO: Decide error message, lines etc.
    
    HashMap<String, HashSet<ClassContentElement<? extends Type>>> allSymbols = new HashMap<String, HashSet<ClassContentElement<? extends Type>>>();
    
    HashSet<UserDefinedType> superClasses = null;
    
    HashMap<String, ClassContentElement<Type>> fields = null;
    
    HashMap<String, ClassContentElement<UserDefinedType>> innerTypes = null;
    
    /*
     * Methods are represented as a multi map to support method overloading.
     * That is, every name is maped to another map from a signature to a class Method
     * object. 
     */
    HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>> methods = null;
    
    HashSet<String> visibleTypeNames = null;
    
    DefinesNamespace belongsTo;
    
    boolean isDefined;
    
    private boolean isOverrider(String name, Method m) throws ErrorMessage{
        if(this.superClasses == null) return false;
        HashSet<Method> methodsInSuper = new HashSet<Method>();
        collectVirtualsInBases(name, m, new HashSet<UserDefinedType>(), methodsInSuper);
        for(Method method : methodsInSuper){
            if(m.isOverriderFor(method) == false) throw new ErrorMessage("");
        }
        return true;
    }
    
    private void collectVirtualsInBases(String name, Method m, HashSet<UserDefinedType> visited, HashSet<Method> res){
        if(visited.contains(this) == true) return;
        visited.add(this);
        if(this.methods != null && this.methods.containsKey(name) == true){
            HashMap<Method.Signature, ClassContentElement<Method>> ms = this.methods.get(name);
            ClassContentElement<Method> supermElem = ms.get(m.getSignature());
            if(supermElem != null){
                Method superm = supermElem.element;
                if(superm.isVirtual) res.add(superm);
            }
        }
        if(this.superClasses != null){
            for(UserDefinedType t : this.superClasses){
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
    
    private int searchSuperType(UserDefinedType t){
        int count = 0;
        if(this.superClasses.contains(t) == true) ++count;
        if(this.superClasses != null){
            for(UserDefinedType ut : this.superClasses){
                if(ut.equals(t) == false) count += ut.searchSuperType(t);
            }
        }
        return count;
    }
    
    private void addInnerTypesToVisible(HashSet<String> set, HashSet<UserDefinedType> visited){
        if(visited.contains(this) == true) return;
        visited.add(this);
        if(this.innerTypes != null){
            for(String key : this.innerTypes.keySet()) set.add(key);
        }
        if(this.superClasses != null){
            for(UserDefinedType t : this.superClasses) t.addInnerTypesToVisible(set, visited);
        }
    }
    
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
            return element.hashCode();
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
     * @param isDefined  whether the type is yet implemented or not.
     * @param belongsTo   The namespace that the type belongs to (either a class or a namespace).
     */
    public UserDefinedType(String name, DefinesNamespace belongsTo, boolean isDefined){
        super(name);
        this.isDefined = isDefined;
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
    public UserDefinedType(String name, DefinesNamespace belongsTo, ArrayList<UserDefinedType> superTypes){
        super(name);
        superClasses = new HashSet<UserDefinedType>();
        for(UserDefinedType s : superTypes)
            /*TODO: handle the fields of superclasses 
             *(according to design at most one is allowed to have)
             * also handle methods, fields and inner types.
             */
            superClasses.add(s);
        this.isDefined = true;
        this.belongsTo = belongsTo;
        this.visibleTypeNames = new HashSet<String>();
        this.addInnerTypesToVisible(visibleTypeNames, new HashSet<UserDefinedType>());
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
    public void insertInnerType(String name, UserDefinedType t, AccessSpecifier access, boolean isStatic) throws ErrorMessage{
        if(this.innerTypes == null) this.innerTypes = new HashMap<String, ClassContentElement<UserDefinedType>>();
        if(name.equals(this.name) == true) throw new ErrorMessage("");
        if(allSymbols.containsKey(name) == true) throw new ErrorMessage("");
        String key = name;
        if(innerTypes.containsKey(key)){
            /*
             * check only if there is another inner type it the same namespace.
             */
            UserDefinedType t1 = innerTypes.get(key).element;
            if(t1.isDefined == false){
                innerTypes.put(key, new ClassContentElement<UserDefinedType>(t, access, isStatic));
                return;
            }
            else if(t.isDefined == true){
                throw new ErrorMessage("");
            }
            else{
                return; //check this one with an example.
            }
        }
        this.visibleTypeNames.add(name);
        t.setVisibleTypeNames(this.visibleTypeNames);
        innerTypes.put(key, new ClassContentElement<UserDefinedType>(t, access, isStatic));
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
            if(m1.containsKey(m.s)) throw new ErrorMessage("");
            if(isOverrider(name, m) == true) m.isVirtual = true;
            m1.put(m.s, new ClassContentElement<Method>(m, access, isStatic));
        }
        else{
            if(allSymbols.containsKey(name) == true) throw new ErrorMessage("");
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = new HashMap<Method.Signature, ClassContentElement<Method>>();
            ClassContentElement<Method> method = new ClassContentElement<Method>(m, access, isStatic);
            if(isOverrider(name, m) == true) m.isVirtual = true;
            m1.put(m.s, method);
            methods.put(name, m1);
            insertInAllSymbols(name, method);
        }
        m.setNamespace(this);
    }
    
    @Override
    public boolean equals(Object o){
        if(!super.equals(o)) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            if(this.belongsTo == ut.belongsTo) return true;
            return false;
        }
        else return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 71 * hash + (this.superClasses != null ? this.superClasses.hashCode() : 0);
        hash = 71 * hash + (this.fields != null ? this.fields.hashCode() : 0);
        hash = 71 * hash + (this.innerTypes != null ? this.innerTypes.hashCode() : 0);
        hash = 71 * hash + (this.methods != null ? this.methods.hashCode() : 0);
        hash = 71 * hash + (this.belongsTo != null ? this.belongsTo.hashCode() : 0);
        hash = 71 * hash + (this.isDefined ? 1 : 0);
        return hash + 71*super.hashCode();              //super's hashcode added for field name ...
    }

    @Override
    public boolean subType(Type o) throws ErrorMessage{
        if(o == null) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            return ut.equals(this);
//            if(superClasses.contains(ut) || ut.equals(this)) return true;
//            for(Iterator<UserDefinedType> it = superClasses.iterator() ; it.hasNext() ; ){
//                UserDefinedType t = it.next();
//                if(t.subType(ut)) return true;
//            }
//            return false;
        }
        return false;
    }
    
    public boolean isCovariantWith(UserDefinedType t) throws ErrorMessage {
        if(t == null) return false;
        /*
         * checking cv-qualifiers for class type according to C++ standard.
         */
        if(super.equals(t) == false){
            if(this.isConst == true || this.isVolatile == true){
                if(t.isConst == false && t.isVolatile == false) return false;
            }
            if(this.isConst == true && this.isVolatile == true){
                if(t.isConst == false || t.isVolatile == false) return false;
            }
        }
        if(t.equals(this) == true) return true;
        int baseClassCount = searchSuperType(t);
        if(baseClassCount > 1) throw new ErrorMessage("");  //base class is ambiguous
        if(baseClassCount == 1) return true;
        return false;                                       //types are not converiant
    }
    
    public boolean isDefined(){
        return this.isDefined;
    }
    
    /*
     * DefinesNamespace Methods
     */
    
    @Override
    public Type findSymbol(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Type findSymbol(String name, DefinesNamespace fromNamespace) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public DefinesNamespace findNamespace(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Method findMethod(String name, Signature s) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Type findField(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }
    
}
