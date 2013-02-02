package errorHandling;

/**
 * Class for creating error messages when user provides wrong
 * arguments for a STL container. C+- does not support 
 * all the arguments for all the STL containers (e.g., a user cannot
 * provide an allocator class at template instantiation).
 * 
 * @author kostas
 */
public class InvalidStlArguments extends ErrorMessage{
    
    /**
     * The second line for the error message (different for every container).
     */
    private String final_err;

    /**
     * Constructs an object given the container name (e.g., vector)
     * and the specific error message for this container.
     * 
     * @param container_name Container 's name.
     * @param err The error message for the above container.
     */
    public InvalidStlArguments(String container_name, String err){
        super("error: invalid arguments for " + container_name + "container");
        this.final_err = err;
    }
    
    /**
     * Returns error message's last line.
     * 
     * @return The error for the container.
     */
    public String getFinalErr(){
        return this.final_err;
    }

}
