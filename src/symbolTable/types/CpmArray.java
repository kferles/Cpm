/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import errorHandling.VoidDeclaration;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.TypeDefinition;
import symbolTable.namespace.SynonymType;

/**
 *
 * @author kostas
 */
public class CpmArray extends Type {

    Type array_of;
    
    int dimensions_num;

    public CpmArray(Type array_of, int dimensions_num) {
        this.array_of = array_of;
        this.dimensions_num = dimensions_num;
    }
    
    public Type getType(){
        return this.array_of;
    }
    
    public void setType(Type array_of){
        this.array_of = array_of;
    }
    
    public void increaseDimensions(){
        this.dimensions_num++;
    }
    
    @Override
    public boolean equals(Object o){
        if(o == null) return false;
        if(o instanceof CpmArray){
            CpmArray ar = (CpmArray) o;
            if(this.array_of.equals(ar.array_of) == false) return false;
            if(this.dimensions_num != ar.dimensions_num) return false;
            return true;
        }
        return false;
    }

    @Override
    public int hashCode() {
        int hash = 3;
        hash = 67 * hash + (this.array_of != null ? this.array_of.hashCode() : 0);
        hash = 67 * hash + this.dimensions_num;
        return hash;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr) {
        aggr.append(" ");
        for(int i = 0 ; i < this.dimensions_num ; ++i){
            aggr.append("[]");
        }
        return array_of.getString(aggr);
    }

    @Override
    public boolean subType(Type o) throws AmbiguousBaseClass {
        return this.equals(o);
    }
    
    @Override
    public boolean isComplete(CpmClass current) throws VoidDeclaration{
        return this.array_of.isComplete(current);
    }
    
    public Pointer convertToPointer(){
        Pointer rv = new Pointer(null, false, false);
        Pointer pend = rv;
        for(int i = 1 ; i < dimensions_num ; ++i){
            Pointer p = new Pointer(null, false, false);
            pend.pointsTo = p;
            pend = p;
        }
        pend.pointsTo = this.array_of;
        return rv;
    }

    @Override
    public boolean isOverloadableWith(Type o, boolean _) {
        if(o instanceof CpmArray){
            CpmArray ar = (CpmArray) o;
            if(this.dimensions_num != ar.dimensions_num) return true;
            return !this.array_of.equals(ar.array_of);
        }
        else if(o instanceof Pointer){
            return this.convertToPointer().isOverloadableWith(o, true);
        }
        else if(o instanceof UserDefinedType){
            return ((UserDefinedType)o).isOverloadableWith(this, false);
        }
        return true;
    }

    @Override
    public boolean isOverloadableWith(TypeDefinition o, boolean isPointer) {
        if(o instanceof SynonymType){
            SynonymType s_t = (SynonymType)o;
            if(s_t.getTag().equals("typedef") == true){
                return this.isOverloadableWith(s_t.getSynonym(), isPointer);
            }
        }
        return true;
    }
    
    @Override
    public int overloadHashCode(boolean _) {
        return this.convertToPointer().overloadHashCode(true);
    }
    
}
