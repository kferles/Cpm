package errorHandling;

import symbolTable.namespace.TypeDefinition;

/**
 * Class for creating error messages when a base class in a class declaration
 * has cv qualifiers (i.e., const and volatile).
 * Example:
 * 
 * class A : public const B {  //error: base class 'B' has cv qualifiers
 * 
 * };
 * 
 * @author kostas
 */
public class BaseClassCVQual extends ErrorMessage{
    
    /**
     * Creating an object given the TypeDefinition instance of the base class.
     * 
     * @param t The base class.
     */
    
    public BaseClassCVQual(TypeDefinition t){
        super("error: base class '" + t.toString() +"' has cv qualifiers");
    }
    
}
