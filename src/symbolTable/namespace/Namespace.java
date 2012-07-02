package symbolTable.namespace;

import java.util.HashMap;
import symbolTable.DefinesNamespace;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    HashMap<String, Type> fields;
    
    HashMap<String, HashMap<Method.Signature, Method>> methods;
    
    HashMap<String, Namespace> innerNamespaces;
    
    //insert ...
}
