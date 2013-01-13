package errorHandling;

import java.util.ArrayList;
import java.util.List;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.MemberElementInfo;
import symbolTable.namespace.Namespace;
import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;

/**
 * Class for creating error messages when there is an ambiguous reference to
 * an identifier. These are multiple line messages, because they list all
 * the possible candidates for the identifier.
 * 
 * Example:
 * 
 *  class A {
 *    class B {};
 *  };
 * 
 * 
 *  class C {
 *    int B;
 *  };
 * 
 * 
 *  class D : public A, public C{
 *    B *b; //filename thisLine:thisPos error: reference to B is ambiguous
 *          //classA'sFilename classB'sLine:classB'sPos error: candidates are : class B
 *          //classC'sFilename classC'sLine:classC'sPos error:                  int B
 *  };
 * 
 * @author kostas
 */
public class AmbiguousReference extends ErrorMessage {
    
    /**
     * All the lines for the candidates of the error message.
     */
    private List<String> lines_errors = new ArrayList<String>();

    /**
     * The ambiguous referenced identifier.
     */
    private String referenced_name;

    /**
     * The last valid namespace. This is for cases, where 
     * the parser tries input as a type.
     */
    private DefinesNamespace last_valid;

    /**
     * This the head of the message (i.e error: reference to identifier is ambiguous).
     */
    private String referenced_err;

    /**
     * This is the last line of the error message (after listing all the candidates).
     * This optional for some cases.
     */
    private String final_err;

    /**
     * Determines whether the error is pending or not. That is, in some cases parser tries
     * to recognize an input but it has more than one alternatives. So, if it fails with the
     * first one, it tries the second one and so on. Variable isPending is by default to false
     * and if there are more alternatives it should be manually set to true.
     */
    boolean isPending = false;
    
    /**
     * Creates an error message given all the candidates for the referenced name.
     * 
     * @param candidatesTypes Candidates types for the referenced name.
     * @param candidateNameSpaces Candidate namespaces for the referenced name.
     * @param candidateFields Candidate fields for the referenced name.
     * @param referenced_name The referenced identifier.
     */
    public AmbiguousReference(List<TypeDefinition> candidatesTypes,
                              List<Namespace> candidateNameSpaces,
                              List<? extends MemberElementInfo<? extends Type>> candidateFields,
                              String referenced_name){

        super("");

        if(candidatesTypes == null || candidateNameSpaces == null || candidateFields == null || referenced_name == null){
            throw new IllegalArgumentException();
        }
        
        this.referenced_name = referenced_name;
        boolean typesEmpty, namespacesEmpty = false;
        
        
        if((typesEmpty = candidatesTypes.isEmpty()) == false){
            TypeDefinition firstClass = candidatesTypes.get(0);
            lines_errors.add(firstClass.getFileName() + " line " + firstClass.getLine() + ":" + firstClass.getPosition()
                                    + " error: candidates are: " + firstClass.toString() + "\n");
            for(int i = 1 ; i < candidatesTypes.size() ; ++i){
                TypeDefinition _class = candidatesTypes.get(i);
                lines_errors.add(_class.getFileName() + " line " + _class.getLine() + ":" + _class.getPosition()
                                                    + " error:                 " + _class.toString() + "\n");
            }
        }
        
        if(typesEmpty && (namespacesEmpty = candidateNameSpaces != null ? candidateNameSpaces.isEmpty() : true) == false){
            Namespace firstNamespace = candidateNameSpaces.get(0);
            this.lines_errors.add(firstNamespace.getFileName() + " line " + firstNamespace.getLine() + ":" + firstNamespace.getPos()
                                  + " error: candidates are: " + firstNamespace + "\n");
        }

        for(int i = (typesEmpty && !namespacesEmpty) ? 1 : 0 ; i < candidateNameSpaces.size() ; ++i){
            Namespace namespace = candidateNameSpaces.get(i);
            this.lines_errors.add(namespace.getFileName() + " line " + namespace.getLine() + ":" + namespace.getPos()
                                  + " error:                 " + namespace + "\n");
        }
        
        if(typesEmpty && namespacesEmpty){
            MemberElementInfo<? extends Type> firstField = candidateFields.get(0);
            this.lines_errors.add(firstField.getFileName() + " line " + firstField.getLine() + ":" + firstField.getPos()
                                  + " error: candidates are: " + firstField.getElement().toString(referenced_name) + "\n");
        }
        
        for(int i = (typesEmpty && namespacesEmpty) ? 1 : 0 ; i < candidateFields.size() ; ++i){
            MemberElementInfo<? extends Type> memberInf = candidateFields.get(i);
            lines_errors.add(memberInf.getFileName() + " line " + memberInf.getLine() + ":" + memberInf.getPos()
                             + " error:                 " + memberInf.getElement().toString(referenced_name) + "\n");
        }
    }
    
    /**
     * Sets the last valid namespace.
     * 
     * @param last_valid The last valid namespace looking for the identifier.
     */
    public void setLastValid(DefinesNamespace last_valid){
        this.last_valid = last_valid;
    }
    
    
    /**
     * Returns the error message for the candidates (all the lines).
     * 
     * @return The error message.
     */
    @Override
    public String getMessage(){
        StringBuilder rv = new StringBuilder();
        
        for(String line : lines_errors){
            rv.append(line);
        }
        
        return rv.toString();
    }
    
    /**
     * Returns the reference error. That is, reference to 'identifier' is ambiguous.
     * 
     * @return The text for the above error.
     */
    public String getRefError(){
        return this.referenced_err;
    }
    
    /**
     * Returns the last line of the error message (after the list of all candidates).
     * 
     * @return The text for the last line of the error message.
     */
    public String getLastLine(){
        return this.final_err;
    }

    /**
     * Sets the reference error message. It takes the line and the pos of the ambiguous reference to the identifier.
     * 
     * @param line The line of the error.
     * @param pos  The position in the above line.
     */
    public void referenceTypeError(int line, int pos){
        this.referenced_err = "line " + line + ":" + pos + " error: reference to '" + this.referenced_name +"' is ambiguous";
    }
    
    /**
     * Creates error message's last line, when parser tries to recognize a type. 
     * 
     * @param line The line of the error message.
     * @param pos  The position in the above line.
     */
    public void finalizeErrorMessage(int line, int pos){
        String msg = "line " + line + ":" + pos + " error: '" + this.referenced_name + "'";
        if(this.last_valid != null){
            msg += "in '" + this.last_valid +"'";
        }
        msg += " does not name a type";
        this.final_err = msg;
    }
    
    /**
     * Creates error message's last line, when parser tries to recognize a type
     */
    public void finalizeErrorMessage(){
        String msg = "error: '" + this.referenced_name + "'";
        if(this.last_valid != null){
            msg += "in '" + this.last_valid +"'";
        }
        msg += " does not name a type";
        this.final_err = msg;
    }
    
    /**
     * Sets is pending variable to true. That means that error message will be printed
     * only if the parser fails to parse the input with a different alternative.
     */
    public void setIsPending(){
        this.isPending = true;
    }
    
    /**
     * Returns the value of the isPending variable.
     * 
     * @return The value of the isPending variable.
     */
    public boolean isPending(){
        return this.isPending;
    }
    
    
}
