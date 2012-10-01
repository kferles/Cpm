package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import java.util.ArrayList;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.NamedType;
import symbolTable.namespace.SynonymType;

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
    
    public void setPointsTo(Type pointsTo){
        this.pointsTo = pointsTo;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr){
        if(pointsTo instanceof Method){
            String end = null;
            Method m = (Method) pointsTo;
            StringBuilder methRv = new StringBuilder();
            methRv.append(m.s.returnValue);
            int rParIndex = methRv.indexOf(")");
            if(rParIndex != -1){
                String start = methRv.substring(0, rParIndex);
                end = methRv.substring(rParIndex, methRv.length());
                methRv = new StringBuilder(start);
            }
            methRv.append(" (");
            if(aggr.length() != 0 && aggr.charAt(0) != '*'){
                methRv.append("*");
                if(this.isConst == true || this.isVolatile){
                    methRv.append(this.isConst == true ? " const" : "");
                    methRv.append(this.isVolatile == true ? " volatile" : "");
                    methRv.append(" ");
                }
                aggr = methRv.append(aggr);
            }
            else{
                aggr = methRv.append(aggr);
                aggr.append("*");
                if(this.isConst == true || this.isVolatile == true){
                    aggr.append(this.isConst == true ? " const" : "");
                    aggr.append(this.isVolatile == true ? " volatile" : "");
                    aggr.append(" ");
                }
            }
            aggr.append(")(");
            ArrayList<Type> parameters = m.s.parameters;
            if(parameters != null){
                int size = parameters.size();
                for(int i = 0 ; i < size ; ++i){
                    aggr.append(i == 0 ? "" : ",");
                    aggr.append(parameters.get(i));
                }
            }
            if(m.hasVarArgs == true){
                if(parameters != null) aggr.append(", ...");
                else                   aggr.append("...");
            }
            aggr.append(")");
            if(m.isConst == true) aggr.append(" const");
            if(m.isVolatile == true) aggr.append(" volatile");
            if(end != null)
                aggr.append(end);
            return aggr;
        }
        else if(this.pointsTo instanceof CpmArray){
            CpmArray ar = (CpmArray) this.pointsTo;
            StringBuilder start = new StringBuilder(ar.array_of.toString());
            String end = null;
            int rParIndex = start.indexOf(")");
            if(rParIndex != -1){
                end = start.substring(rParIndex, start.length());
                start = new StringBuilder(start.substring(0, rParIndex));
            }
            start.append(" (");
            aggr = start.append(aggr);
            aggr.append("*");
            if(this.isConst == true || this.isVolatile == true){
                if(this.isConst == true) start.append(" const");
                if(this.isVolatile == true) start.append(" volatile");
                start.append(" ");
            }
            aggr.append(") ");
            for(int i = 0 ; i < ar.dimensions_num ; ++i){
                aggr.append("[]");
            }
            if(end != null) aggr.append(end);
            return aggr;
        }
        else{
            StringBuilder id = null;
            String start = null;
            String end = null;
            if(aggr.length() != 0 && aggr.charAt(0) != '*'){
                id = new StringBuilder(" ").append(aggr);
                aggr = new StringBuilder();
            }
            aggr.append("*");
            if(this.isConst == true || this.isVolatile == true){
                aggr.append(this.isConst == true ? " const" : "");
                aggr.append(this.isVolatile == true ? " volatile" : "");
                aggr.append(" ");
            }
            StringBuilder pTo = this.pointsTo.getString(aggr);
            int rParIndex = pTo.indexOf(")");
            if(rParIndex != -1 && id != null){
                start = pTo.substring(0, rParIndex);
                end = pTo.substring(rParIndex, pTo.length());
                start += id.toString();
            }
            if(start != null && end != null){
                return new StringBuilder(start + end);
            }
            return pTo.append(id != null ? id : "");
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
        hash = 83 * hash + super.hashCode();
        hash = 83 * hash + (this.pointsTo != null ? this.pointsTo.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean subType(Type o) throws AmbiguousBaseClass {
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
    
    @Override
    public boolean isComplete(CpmClass _){
        return true;
    }
    
    @Override
    public boolean isOverloadableWith(Type o, boolean _){
        if(o instanceof Pointer){
            Pointer p = (Pointer) o;
            return this.pointsTo.isOverloadableWith(p.pointsTo, true);
        }
        else if(o instanceof CpmArray){
            CpmArray ar = (CpmArray)o;
            Pointer n_p = ar.convertToPointer();
            return this.isOverloadableWith(n_p, true);
        }
        else if(o instanceof UserDefinedType){
            return ((UserDefinedType)o).isOverloadableWith(this, false);
        }
        return true;
    }
    
    @Override
    public boolean isOverloadableWith(NamedType nt, boolean _){
        if(nt instanceof SynonymType){
            SynonymType s_t = (SynonymType)nt;
            if(s_t.getTag().equals("typedef") == true){
                return this.isOverloadableWith(s_t.getSynonym(), false);
            }
        }
        return true;
    }
    
    @Override
    public int overloadHashCode(boolean isPointer) {
        return this.pointsTo.overloadHashCode(true);
    }
    
}
