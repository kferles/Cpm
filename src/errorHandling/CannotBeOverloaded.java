package errorHandling;

/**
 * Class for creating error messages when two method cannot be overloaded.
 * 
 * @author kostas
 */
public class CannotBeOverloaded extends ErrorMessage{
    
    /**
     * Holds the last line of the message. It denotes the method that the new methods conflicts with.
     */
    String final_err = null;
    
    /**
     * Creates a new instance from the old and new methods.
     * 
     * @param new_m The new method (the one that rises the conflict).
     * @param old_m The old method (the one already inserted in the current scope).
     * @param new_line The line of the new method.
     * @param new_pos The position in the above line.
     * @param olds_fileName The filename of the old method.
     * @param old_line The line of the old method.
     * @param old_pos  The position in the above line.
     */
    public CannotBeOverloaded(String new_m, String old_m, int new_line, int new_pos, String olds_fileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_m + "' cannot be overloaded");
        this.final_err = olds_fileName + " line " + old_line + ":" + old_pos + " error: with '" + old_m + "'";
    }
    
    /**
     * Returns message's last line.
     * 
     * @return The text for the conflicted methods.
     */
    public String getFinalError(){
        return this.final_err;
    }
    
}
