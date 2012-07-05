package symbolTable.types;

import errorHandling.ErrorMessage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
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
    
    DefinesNamespace belongsTo;
    
    boolean isDefined;
    
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
        if(allSymbols.containsKey(key) == true) throw new ErrorMessage("");
        //if(fields.containsKey(key)) throw new ErrorMessage(""); //with allSymbols HashMap this is probably useless.
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
        //TODO: according to the name of the new type and the existings names in allSymbos HashMap, which type names will be legal for C+- ?
        if(this.innerTypes == null) this.innerTypes = new HashMap<String, ClassContentElement<UserDefinedType>>();
        if(name.equals(this.name) == true) throw new ErrorMessage("");
        String key = name;
        if(innerTypes.containsKey(key)){
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
        //TODO: check for methods in super classes and if a virtual method is being overriden make it virtual in this class as well. Also for access & (const, virtual, etc) specifiers in the same and super classes (for overriding).
        if(this.methods == null) this.methods = new HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>>();
        if(methods.containsKey(name)){
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = methods.get(name);
            if(m1.containsKey(m.s)) throw new ErrorMessage("Hello");
            m1.put(m.s, new ClassContentElement<Method>(m, access, isStatic));
        }
        else{
            if(allSymbols.containsKey(name) == true) throw new ErrorMessage("");
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = new HashMap<Method.Signature, ClassContentElement<Method>>();
            ClassContentElement<Method> method = new ClassContentElement<Method>(m, access, isStatic);
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
    public boolean subType(Type o) {
        if(o == null) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            if(superClasses.contains(ut) || ut.equals(this)) return true;
            for(Iterator<UserDefinedType> it = superClasses.iterator() ; it.hasNext() ; ){
                UserDefinedType t = it.next();
                if(this.subType(t)) return true;
            }
            return false;
        }
        return false;
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
