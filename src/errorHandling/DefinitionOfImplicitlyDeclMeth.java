package errorHandling;

import symbolTable.namespace.CpmClass;

/**
 *
 * @author kostas
 */
public class DefinitionOfImplicitlyDeclMeth extends ErrorMessage {
    
    public DefinitionOfImplicitlyDeclMeth(CpmClass _class, boolean isDestructor){
        super("error: definition of implicitly-declared '" + _class.getFullName() + "::" 
               + (isDestructor ? "~" : "") + _class.getName() + "()'");
    }
    
}
