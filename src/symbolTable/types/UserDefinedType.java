package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import errorHandling.VoidDeclaration;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.NamedType;
import symbolTable.namespace.SynonymType;

/**
 *
 * @author kostas
 */
public class UserDefinedType extends SimpleType{

    NamedType type;
    
    public UserDefinedType(NamedType type, boolean isConst, boolean isVolatile) {
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
    public boolean subType(Type o) throws AmbiguousBaseClass{
        if(o == null) return false;
        if(o instanceof UserDefinedType){
            UserDefinedType ut = (UserDefinedType) o;
            return ut.equals(this);
        }
        return false;
    }
    
    public boolean isCovariantWith(UserDefinedType t) throws AmbiguousBaseClass  {
        if(t == null) return false;
        if(this.type instanceof CpmClass){
            if(t.type instanceof CpmClass){
                /*
                 * checking cv-qualifiers for class type according to C++ standard.
                 */
                CpmClass c1 = (CpmClass) this.type, c2 = (CpmClass) t.type;
                if(super.equals(t) == false){
                    if(this.isConst == true || this.isVolatile == true){
                        if(t.isConst == false && t.isVolatile == false) return false;
                    }
                    if(this.isConst == true && this.isVolatile == true){
                        if(t.isConst == false || t.isVolatile == false) return false;
                    }
                }
                return c1.isCovariantWith(c2);
            }
            else{
                Type syn_t = ((SynonymType) this.type).getSynonym();
                if(syn_t instanceof UserDefinedType){
                    return this.isCovariantWith((UserDefinedType) syn_t);
                }
                else return false;
            }
        }
        else{
            SynonymType t1 = (SynonymType) this.type;
            Type syn_t = t1.getSynonym();
            if(syn_t instanceof UserDefinedType){
                return ((UserDefinedType) syn_t).isCovariantWith(t);
            }
            else return false;
            
        }
    }
    
    public NamedType getNamedType(){
        return this.type;
    }
    
    @Override
    public boolean isComplete(CpmClass current) throws VoidDeclaration{
        return this.type.isComplete(current);
    }
    
}
