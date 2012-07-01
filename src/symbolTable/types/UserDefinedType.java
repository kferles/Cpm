package symbolTable.types;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

/**
 *
 * @author kostas
 */
public class UserDefinedType extends SimpleType {
    
    HashSet<UserDefinedType> superClasses = null;
    
    HashMap<String, Type> fields = null;
    
    HashMap<String, UserDefinedType> innerTypes = null;
    
    /*
     * Methods are represented as a multi map to support method overloading.
     * That is, every name is maped to another map from a signature to a class Method
     * object. 
     */
    HashMap<String, HashMap<Method.Signature, Method>> methods = null;
    
    boolean isAbstract;
    
    /**
     * Constructs a UserDefinedType according to its name.
     * 
     * @param name Type's name.
     * @param isAbstract  whether the type is yet implemented or not.
     */
    public UserDefinedType(String name, boolean isAbstract){
        super(name);
        this.isAbstract = isAbstract;
    }
    
    /**
     * Constructs a UserDefinedType that extends some other classes.
     * The ArrayList must contain unique non abstract types so the 
     * constructor will be responsible for no error checking. All these
     * checks must be performed before calling the constructor.
     * @param name          Type's name.
     * @param superTypes    All the super classes.
     */
    public UserDefinedType(String name, ArrayList<UserDefinedType> superTypes){
        super(name);
        superClasses = new HashSet<UserDefinedType>();
        for(UserDefinedType s : superTypes)
            /*TODO: handle the fields of superclasses 
             *(according to design at most one is allowed to have)
             * also handle methods, fields and inner types.
             */
            superClasses.add(s);
    }
    
    /**
     * Insert a field to the current type.
     * 
     * @param name  Field 's name.
     * @param t     A reference to the object that describes field 's type.
     * @return      True if the field is unique inside the Type and false otherwise.
     */
    public boolean insertField(String name, Type t){
        if(fields == null) fields = new HashMap<String, Type>();
        String key = name;      //think how to distinguish field that shadows fields of superclasses.
        if(fields.containsKey(key)) return false;
        fields.put(key, t);
        return true;
    }
    
    /**
     * Insert an inner type (i.e nested) to the current type.
     * 
     * @param name Type's name.
     * @param t    A reference to the UserDefinedType object that describes the Type.
     * @return     True if this name is unique inside this scope.
     */
    public boolean insertInnerType(String name, UserDefinedType t){
        if(this.innerTypes == null) this.innerTypes = new HashMap<String, UserDefinedType>();
        String key = name;
        if(innerTypes.containsKey(key)){
            UserDefinedType t1 = innerTypes.get(key);
            if(t1.isAbstract == true){
                innerTypes.put(key, t);
                return true;
            }
            else if(t.isAbstract == false){
                return false;
            }
        }
        innerTypes.put(key, t);
        return true;
    }
    
    /**
     * Insert a new method to the current type.
     * 
     * @param name  Method's name.
     * @param m     A reference to the Method object that describes the method
     * @return      True if method can be inserted and false if method cannot be overloaded.
     */
    public boolean insertMethod(String name, Method m){
        if(this.methods == null) this.methods = new HashMap<String, HashMap<Method.Signature, Method>>();
        if(methods.containsKey(name)){
            HashMap<Method.Signature, Method> m1 = methods.get(name);
            if(m1.containsKey(m.s)) return false;
            m1.put(m.s, m);
        }
        else{
            HashMap<Method.Signature, Method> m1 = new HashMap<Method.Signature, Method>();
            m1.put(m.s, m);
            methods.put(name, m1);
        }
        m.setType(this);
        return true;
    }

    @Override
    public boolean subType(Type o) {
        if(o == null) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            String name = ut.name;
            if(innerTypes.containsKey(name)) return true;
            for(UserDefinedType t : innerTypes.values()){
                if(this.subType(t)) return true;
            }
            return false;
        }
        return false;
    }
    
}
