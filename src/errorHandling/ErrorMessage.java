package errorHandling;

import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class ErrorMessage extends Exception{
    
    public static String getFullName(Method m, String name){
        String id = m.getParent().getFullName();
        if(id.equals("") == false) id += "::";
        id += name;
        return id;
    }
    
    public ErrorMessage(String msg){
        super(msg);
    }
    
}
