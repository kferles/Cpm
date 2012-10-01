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
        super(type.getFullName());
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
    
    @Override
    public boolean isOverloadableWith(Type o, boolean isPointer){
        if(o instanceof UserDefinedType){
            if(isPointer == true){
                if(this.isConst != o.isConst) return true;
                if(this.isVolatile != o.isVolatile) return true;
            }
        }
        return o.isOverloadableWith(this.type, isPointer);
    }
    
    @Override
    public boolean isOverloadableWith(NamedType o, boolean isPointer){
        if(this.type instanceof CpmClass){
            CpmClass _class = (CpmClass)this.type;
            if(o instanceof CpmClass){
                return !_class.equals(o);
            }
            else{
                SynonymType s_t = (SynonymType)this.type;
                if(s_t.getTag().equals("typedef") == true) return s_t.getSynonym().isOverloadableWith(this.type, isPointer);
                /*
                 * a class and an emun.
                 */
                return true;
            }
        }
        else{
            SynonymType s_t = (SynonymType)this.type;
            if(o instanceof CpmClass){
                if(s_t.getTag().equals("typedef") == true) return s_t.getSynonym().isOverloadableWith((CpmClass) o, isPointer);
                /*
                 * a class and an enum
                 */
                return true;
            }
            else{
                SynonymType s_t1 = (SynonymType)o;
                if(s_t.getTag().equals("typedef") == true){
                    if(s_t1.getTag().equals("typedef") == true){
                        return s_t.getSynonym().isOverloadableWith(s_t1.getSynonym(), isPointer);
                    }
                    else{
                        return s_t.getSynonym().isOverloadableWith(s_t1, isPointer);
                    }
                }
                else{
                    if(s_t1.getTag().equals("typedef") == true){
                        return s_t1.getSynonym().isOverloadableWith(s_t, isPointer);
                    }
                    else{
                        /*
                         * both are enums
                         */
                        return !s_t.equals(s_t1);
                    }
                }
            }
        }
    }
    
    @Override
    public int overloadHashCode(boolean isPointer) {
        if(this.type instanceof CpmClass){
            int hash = 7;
            if(isPointer == true){
                hash = hash*71 + (this.isConst ? 1 : 0);
                hash = hash*71 + (this.isVolatile ? 1 : 0);
            }
            return hash + this.type.hashCode();
        }
        else{
            SynonymType s_t = (SynonymType)this.type;
            if(s_t.getTag().equals("typedef")) return s_t.getSynonym().overloadHashCode(isPointer);
            else{
                int hash = 7;
                if(isPointer == true){
                    hash = hash*71 + (this.isConst ? 1 : 0);
                    hash = hash*71 + (this.isVolatile ? 1 : 0);
                }
                return hash*71 + s_t.hashCode();
            }
        }
    }
    
}
