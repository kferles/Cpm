package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousReference;
import errorHandling.InvalidScopeResolution;
import java.util.HashMap;


/**
 *
 * @author kostas
 */
public interface DefinesNamespace {
    
    public StringBuilder getStringName(StringBuilder in);
    
    public HashMap<String, TypeDefinition> getVisibleTypeNames();
    
    public DefinesNamespace getParentNamespace();
    
    public String getFullName();
    
    public String getName();
    
    public TypeDefinition isValidNamedType(String name, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference;
    
    public TypeDefinition findNamedType(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference;
    
    public DefinesNamespace findNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution;
    
    public DefinesNamespace findInnerNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution;
    
}