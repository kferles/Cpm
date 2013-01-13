package errorHandling;

import symbolTable.types.Method;

/**
 * Class that represents an error message. It extends Exception, so every error message
 * rises as an exception in the parser. This is the Base class of all error messages handling
 * classes.
 * 
 * @author kostas
 */
public class ErrorMessage extends Exception{
    
    /**
     * Given a method's signature and its name, it returns the full signature as a String.
     * For example:
     * 
     * void A::foo(int, int);
     * 
     * @param m Method's signature information.
     * @param name Method's name.
     * @return The string representation of the signature.
     */
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
