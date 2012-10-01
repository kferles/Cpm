/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.namespace.stl.iterator;

import symbolTable.namespace.CpmClass;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class CpmIterator extends CpmClass{
    
    Type iter_to;

    IteratorType it_type;
    
    boolean isConst;

    public CpmIterator(String name, DefinesNamespace belongsTo, CpmClass.AccessSpecifier access, Type iter_to, IteratorType it_type, boolean isConst){
        super("class", name, belongsTo, access, true);
        this.iter_to = iter_to;
        this.it_type = it_type;
        this.isConst = isConst;
    }
}
