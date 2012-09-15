/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import java.util.ArrayList;
import symbolTable.namespace.Namespace;
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
    
}
