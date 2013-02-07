package symbolTable.namespace;

/**
 *
 * @author kostas
 */
public interface MemberElementInfo<T> {
    
    public String getFileName();
    
    public int getLine();
    
    public int getPos();
    
    public T getElement();
    
    public boolean isStatic();
    
    public boolean isClassMember();
    
    public boolean isDefined();
    
    public void defineStatic(int defLine, int defPos, String defFilename);
    
    public int getStaticDefLine();
    
    public int getStaticDefPos();
    
    public String getStaticDefFile();
    
}
