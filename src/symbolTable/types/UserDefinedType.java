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
    
    HashMap<String, Type> innerTypes = null;
    
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
     * Constructs a UserDefinedType that extends some other classes. HashMap<String, Type> fields = null;
    
    HashMap<String, Type> innerTypes = null;
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
        String key = this.name + "_" + name;
        if(fields.containsKey(key)) return false;
        fields.put(key, t);
        return true;
    }

    @Override
    public boolean subType(Type lhs) {
        throw new UnsupportedOperationException("Not supported yet.");
    }
    
}
