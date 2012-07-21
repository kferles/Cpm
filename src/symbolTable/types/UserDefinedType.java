package symbolTable.types;

import errorHandling.ErrorMessage;
import symbolTable.namespace.Class;

/**
 *
 * @author kostas
 */
public class UserDefinedType extends SimpleType{

    Class type;
    
    public UserDefinedType(Class type, boolean isConst, boolean isVolatile) {
        super(type.getName());
        this.type = type;
        this.isConst = isConst;
        this.isVolatile = isVolatile;
    }

    
    @Override
    public boolean equals(Object o){
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            if(this.isConst != ut.isConst || this.isVolatile != ut.isVolatile) return false;
            if(this.type.equals(ut.type) == false) return false;
            return true;
        }
        else return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 31 * hash + (this.type != null ? this.type.hashCode() : 0);
        hash = 31 * hash + (this.isConst ? 1 : 0);
        hash = 31 * hash + (this.isVolatile ? 1 : 0);
        return hash;
    }


    @Override
    public boolean subType(Type o) throws ErrorMessage{
        if(o == null) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            return ut.equals(this);
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
        if(this.type.isCovariantWith(t.type) == false) return false;
        return true;
    }
    
}
