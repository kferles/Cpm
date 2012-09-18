/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import java.util.ArrayList;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.NamedType;

/**
 *
 * @author kostas
 */
public class AmbiguousReference extends ErrorMessage {
    
    private ArrayList<String> lines_errors = new ArrayList<String>();
    
    private String referenced_type;
    
    private DefinesNamespace last_valid;
    
    private String referenced_err;
    
    private String final_err;
    
    boolean isPending = false;
    
    public AmbiguousReference(ArrayList<NamedType> candidates, String referenced_type){
        super("");
        this.referenced_type = referenced_type;
        NamedType firstClass = candidates.get(0);
        lines_errors.add(firstClass.getFileName() + " line " + firstClass.getLine() + ":" + firstClass.getPosition()
                                + " error: candidates are: " + firstClass.toString() + "\n");
        for(int i = 1 ; i < candidates.size() ; ++i){
            NamedType _class = candidates.get(i);
            lines_errors.add(_class.getFileName() + " line " + _class.getLine() + ":" + _class.getPosition()
                                                  + " error:                 " + _class.toString() + "\n");
        }
    }
    
    public void setLastValid(DefinesNamespace last_valid){
        this.last_valid = last_valid;
    }
    
    @Override
    public String getMessage(){
        StringBuilder rv = new StringBuilder();
        
        for(String line : lines_errors){
            rv.append(line);
        }
        
        return rv.toString();
    }
    
    public String getRefError(){
        return this.referenced_err;
    }
    
    public String getLastLine(){
        return this.final_err;
    }
    
    public void referenceTypeError(int line, int pos){
        this.referenced_err = "line " + line + ":" + pos + " error: reference to '" + this.referenced_type +"' is ambiguous";
    }
    
    public void finalizeErrorMessage(int line, int pos){
        String msg = "line " + line + ":" + pos + " error: '" + this.referenced_type + "'";
        if(this.last_valid != null){
            msg += "in '" + this.last_valid +"'";
        }
        msg += " does not name a type";
        this.final_err = msg;
    }
    
    public void finalizeErrorMessage(){
        String msg = "error: '" + this.referenced_type + "'";
        if(this.last_valid != null){
            msg += "in '" + this.last_valid +"'";
        }
        msg += " does not name a type";
        this.final_err = msg;
    }
    
    public void setIsPending(){
        this.isPending = true;
    }
    
    public boolean isPending(){
        return this.isPending;
    }
    
    
}
