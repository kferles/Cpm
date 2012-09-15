package errorHandling;

/**
 *
 * @author kostas
 */
public class AccessSpecViolation extends ErrorMessage{

    String context_err = "error: whithin this context";
    
    public AccessSpecViolation (String msg){
        super(msg);
    }
    
    public void setContextError(int line, int pos){
        this.context_err = "line " + line + ":" + pos + " " + this.context_err;
    }
    
    public String getContextError(){
        return this.context_err;
    }
    
}
