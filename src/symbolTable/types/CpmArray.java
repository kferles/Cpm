/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import errorHandling.VoidDeclaration;
import symbolTable.namespace.CpmClass;

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
    public String toString(String id){
        return this.getString(new StringBuilder(id)).toString();
    }

    @Override
    public boolean subType(Type o) throws AmbiguousBaseClass {
        throw new UnsupportedOperationException("Not supported yet.");
    }
    
    @Override
    public boolean isComplete(CpmClass current) throws VoidDeclaration{
        return this.array_of.isComplete(current);
    }
    
}
