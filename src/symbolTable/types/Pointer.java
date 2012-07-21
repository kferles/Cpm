package symbolTable.types;

import errorHandling.ErrorMessage;
import java.util.ArrayList;

/**
 *
 * @author kostas
 */
public class Pointer extends Type{
    
    Type pointsTo;
    
    public Pointer(Type pointsTo, boolean isConst, boolean isVolatile){
        this.pointsTo = pointsTo;
        this.isConst = isConst;
        this.isVolatile = isVolatile;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr){
        if(pointsTo instanceof Method){
            String end = null;
            Method m = (Method) pointsTo;
            StringBuilder methRv = new StringBuilder();
            methRv.append(m.s.returnValue);
            int rParIndex = methRv.indexOf(")");
            if(rParIndex == -1){
                methRv.append(" (*");
            }
            else{
                String start = methRv.substring(0, rParIndex);
                end = methRv.substring(rParIndex, methRv.length());
                methRv = new StringBuilder(start);
                methRv.append(" (*");
            }
            aggr.append(")(");
            ArrayList<Type> parameters = m.s.parameters;
            int size = parameters.size();
            for(int i = 0 ; i < size ; ++i){
                aggr.append(i == 0 ? "" : ",");
                aggr.append(parameters.get(i));
            }
            aggr.append(")");
            if(end != null)
                aggr.append(end);
            return methRv.append(aggr);
        }
        else{
            aggr.append("*");
            return pointsTo.getString(aggr);
        }
    }
    
    @Override
    public boolean equals(Object o){
        if(o == null) return false;
        if(o instanceof Pointer){
            if(super.equals(o) == false) return false;
            Pointer p = (Pointer) o;
            return this.pointsTo.equals(p.pointsTo);
        }
        return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 83 * hash + (this.pointsTo != null ? this.pointsTo.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean subType(Type o) throws ErrorMessage {
        if(o == null) return false;
        if(o instanceof Pointer){
            if(super.equals((Type) o) == false) return false;   //check this one from standard for cv-qualifiers
            Pointer p = (Pointer) o;
            if(this.pointsTo instanceof UserDefinedType && p.pointsTo instanceof UserDefinedType){
                /*
                 * special case: A* <: B* only if B is an unambiguous base class of A.
                 *               multiple level of pointers are not allowed.
                 */
                if(super.equals(o) == false) return false; //check cv-qualifiers for pointers to be indentical
                UserDefinedType t1 = (UserDefinedType) this.pointsTo, t2 = (UserDefinedType) p.pointsTo;
                return t1.isCovariantWith(t2);
            }
            return this.pointsTo.equals(p.pointsTo);
        }
        return false;
    }
}
