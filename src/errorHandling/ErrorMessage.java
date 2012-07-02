package errorHandling;

/**
 *
 * @author kostas
 */
public class ErrorMessage {
    
    private String msg;
    
    public ErrorMessage(String msg){
        this.msg = msg;
    }
    
    public String getError(){
        return this.msg;
    }
}
