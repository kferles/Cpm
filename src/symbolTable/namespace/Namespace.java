package symbolTable.namespace;

import errorHandling.ErrorMessage;
import java.util.HashMap;
import symbolTable.DefinesNamespace;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    HashMap<String, Type> fields = null;
    
    HashMap<String, HashMap<Method.Signature, Method>> methods = null;
    
    HashMap<String, Namespace> innerNamespaces = null;
    
    public void insertField(String name, Type t) throws ErrorMessage{
        if(fields == null) fields = new HashMap<String, Type>();
        if(fields.containsKey(name)) throw new ErrorMessage("");
        fields.put(name, t);
    }
    
    public void insertMethod(String name, Method m) throws ErrorMessage{
        if(methods == null) methods = new HashMap<String, HashMap<Method.Signature, Method>>();
        if(methods.containsKey(name)){
            HashMap<Method.Signature, Method> ms = methods.get(name);
            if(ms.containsKey(m.getSignature())) throw new ErrorMessage("");
            ms.put(m.getSignature(), m);
        }
        else{
            HashMap<Method.Signature, Method> new_entry = new HashMap<Method.Signature, Method>();
            new_entry.put(m.getSignature(), m);
            methods.put(name, new_entry);
        }
    }
    
    public void insertInnerNamespace(String name, Namespace namespace) throws ErrorMessage{
        if(innerNamespaces == null) innerNamespaces = new HashMap<String, Namespace>();
        if(!innerNamespaces.containsKey(name)){
            innerNamespaces.put(name, namespace);
        }
        else{
            /*
             * merging the existing namespace with the extension declaration.
             */
            Namespace exists = innerNamespaces.get(name);
            for(String key : namespace.fields.keySet()){
                Type t = namespace.fields.get(key);
                exists.insertField(name, t);
            }
            for(String key : namespace.methods.keySet()){
                HashMap<Method.Signature, Method> ms = namespace.methods.get(key);
                for(Method m : ms.values()){
                    exists.insertMethod(key, m);
                }
            }
            for(String key : namespace.innerNamespaces.keySet()){
                /*
                 * merge again all the inner namespaces.
                 */
                Namespace n = namespace.innerNamespaces.get(key);
                exists.insertInnerNamespace(key, n);
            }
        }
    }
}
