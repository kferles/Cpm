package errorHandling;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.MemberElementInfo;
import symbolTable.types.Method;

/**
 * Class for creating error messages when there is no matching signature for a method call
 * or a method definition.
 * For Example:
 * 
 * class A {
 * 
 *   int foo();
 *   int foo(int, int);
 * 
 * };
 * 
 * //error: prototype for 'void A::foo(double)' does not match any in 'class A'
 * //error: candidates are : int foo();
 * //error:                  int foo(int, int);
 * void A::foo(double d){
 * 
 * }
 * 
 * @author kostas
 */
public class NotMatchingPrototype extends ErrorMessage{
    
    /**
     * All the lines of the error message (one per candidate method).
     */
    List<String> messageLines = new ArrayList<String>();
    
    /**
     * Constructs an object given the method name, the requested method signature and the candidate methods from the
     * namespace that the name lookup was performed (i.e., with the same name).
     * 
     * @param methName method's name.
     * @param requested the method that caused the error,
     * @param candidateMeths the candiadate methods from the namespace that the name lookup was performed.
     * @param namespace the namespace that the lookup was performed.
     */
    public NotMatchingPrototype(String methName,
                                Method requested,
                                Map<Method.Signature, ? extends MemberElementInfo<Method>> candidateMeths,
                                DefinesNamespace namespace){

        super("error: prototype for '" + requested.toString(namespace + "::" + methName) + "' does not match any in '" + namespace + "'");
        
        Collection<? extends MemberElementInfo<Method>> meths = candidateMeths.values();
        Iterator<? extends MemberElementInfo<Method>> it = meths.iterator();
        
        if(candidateMeths.size() == 1){
            MemberElementInfo<Method> elem = it.next();
            messageLines.add(elem.getFileName() + " line " + elem.getLine() + ":" + elem.getPos() 
                             + " error: candidate is: " + elem.getElement().toString(methName) + "\n");
        }
        else{
            MemberElementInfo<Method> elem = it.next();
            messageLines.add(elem.getFileName() + " line " + elem.getLine() + ":" + elem.getPos() 
                             + " error: candidate are: " + elem.getElement().toString(methName) + "\n");

            while(it.hasNext()){
                elem = it.next();
                messageLines.add(elem.getFileName() + " line " + elem.getLine() + ":" + elem.getPos() 
                                 + "                       " + elem.getElement().toString(methName) + "\n");
            }
        }
    }
    
    /**
     * Constructs the part of the message that contain all the candidate methods.
     * The rest part can be retrieved by the getMessage method.
     * 
     * @return The String representation of the error message.
     */
    public String makeMessage(){
        StringBuilder rv = new StringBuilder();
        for(String s : this.messageLines) rv.append(s);
        return rv.toString();
    }
    
}
