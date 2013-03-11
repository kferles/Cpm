package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousReference;
import errorHandling.InvalidScopeResolution;
import java.util.Map;


/**
 *
 * @author kostas
 */
public interface DefinesNamespace {
    
    public StringBuilder getStringName(StringBuilder in);
    
    public Map<String, TypeDefinition> getVisibleTypeNames();
    
    public DefinesNamespace getParentNamespace();
    
    public String getFullName();
    
    public String getName();
    
    public TypeDefinition isValidTypeDefinition(String name, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference;
    
    public TypeDefinition findTypeDefinition(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference;
    
    public DefinesNamespace findNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution;
    
    public DefinesNamespace findInnerNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution;
    
    public  LookupResult localLookup(String name, DefinesNamespace from_scope, boolean searchInSupers, boolean ignore_access);
    
    public boolean isEnclosedInNamespace(DefinesNamespace namespace);
    
    public void resetNonClassFields();
    
}