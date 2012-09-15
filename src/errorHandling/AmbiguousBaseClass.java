/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.CpmClass;

/**
 *
 * @author kostas
 */
public class AmbiguousBaseClass extends ErrorMessage{
    
    public AmbiguousBaseClass(CpmClass base, CpmClass derived){
        super("error: '" + base.getName() + "'is an ambiguous base of '" + derived.getName() + "'");
    }
    
}
