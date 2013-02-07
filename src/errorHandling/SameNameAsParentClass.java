package errorHandling;

import symbolTable.namespace.TypeDefinition;

/**
 * Class for creating error messages when there is a declaration inside a class
 * that has the same name (with the class).
 * 
 * @author kostas
 */
public class SameNameAsParentClass extends ErrorMessage{
    
    /**
     * Creates an object given the entry's type information.
     * @param t Entry's type information.
     */
    public SameNameAsParentClass(TypeDefinition t){
        super("line " + t.getLine() + ":" + t.getPosition() + " error: '" + t.toString() + "' has the same name as the class in which it is declared");
    }
    
}
