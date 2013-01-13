package errorHandling;

import symbolTable.namespace.CpmClass;

/**
 * Class for creating error messages when there is
 * a cast from a class to an ambiguous base class (since
 * C+- does not have virtual inheritance this is the default 
 * case).
 * Example:
 * 
 *        A
 *      /   \
 *     B     C
 *      \   /
 *        D
 * 
 *    D * d = new D();
 *    A * a = d; //error: 'A' is an ambiguous base of 'D'
 * 
 * @author kostas
 */

public class AmbiguousBaseClass extends ErrorMessage{
    
    /**
     * Creates an AmbiguousBassClass instance given the Base and Derived classes.
     * 
     * @param base The base class.
     * @param derived The derived class.
     */
    
    public AmbiguousBaseClass(CpmClass base, CpmClass derived){
        super("error: '" + base.getFullName() + "'is an ambiguous base of '" + derived.getFullName() + "'");
    }
    
}
