/** ANSI C ANTLR v3 grammar

Translated from Jutta Degener's 1995 ANSI C yacc grammar by Terence Parr
July 2006.  The lexical rules were taken from the Java grammar.

Jutta says: "In 1985, Jeff Lee published his Yacc grammar (which
is accompanied by a matching Lex specification) for the April 30, 1985 draft
version of the ANSI C standard.  Tom Stockfisch reposted it to net.sources in
1987; that original, as mentioned in the answer to question 17.25 of the
comp.lang.c FAQ, can be ftp'ed from ftp.uu.net,
   file usenet/net.sources/ansi.c.grammar.Z.
I intend to keep this version as cu discover discrepancies. Jutta Degener, 1995"

Generally speaking, you need symbol table info to parse C; typedefs
define types and then IDENTIFIERS are either types or plain IDs.  I'm doing
the min necessary here tracking only type names.  This is a good example
of the global scope (called Symbols).  Every rule that declares its usage
of Symbols pushes a new copy on the stack effectively creating a new
symbol scope.  Also note rule declaration declares a rule scope that
lets any invoked rule see isTypedef boolean.  It's much easier than
passing that info down as parameters.  Very lose to the current C Standard grammar as
possible; please let me know if yoclean.  Rule
direct_declarator can then easily determine whether the IDENTIFIER
should be declared as a type name.

I have only tested this on a single file, though it is 3500 lines.

This grammar requires ANTLR v3.0.1 or higher.

Terence Parr
July 2006
*/ 
grammar Cpm;
options {
    backtrack=true;
    memoize=true;
    k=2;
    output=AST;
}

scope Type_Spec{
	boolean error_for_signed, error_for_unsigned;
	boolean type[];
	PrimitiveTypeCheck counters;
}

scope cv_qual{
	boolean error_for_const, error_for_volatile;
	int constCount;
	int volatileCount;
}

scope storage_class_spec{
	boolean error_found;
	int externCount;
	int staticCount;
	int autoCount;
	int registerCount;
}

@header {
import java.util.Set;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;
import symbolTable.types.*;
}

@members {
	//error messages
	Stack paraphrases = new Stack();
	
	public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
		//Change line number in error reporting HERE !!!!
		//e.line++;
		super.displayRecognitionError(tokenNames, e);
        }
	
	public String getErrorMessage(RecognitionException e, String[] tokenNames){
		//e.token.setLine(e.token.getLine()+1);
		if(paraphrases.size() > 0){
			String rv = "";
			for(Object o : paraphrases)
				rv += (String) o;
			paraphrases.clear();
			return rv;
		}
		return super.getErrorMessage(e, tokenNames);
	}
	
	private Object error(String msg){
		paraphrases.push(msg);
		//throw new RecognitionException();
		return null;
	}
	
	private boolean direct_declarator_error(String declarator, String error){
		if(error == null) return true;
		error += " '" + declarator + '\'';
		paraphrases.push(error);
		return false;
	}
	
	private boolean const_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_const == true) return true;
		if(cv_quals.constCount > 1){
			cv_quals.error_for_const = true;
			paraphrases.push("error: duplicate 'const'");
			return false;
		}
		return true;
	}
	
	private boolean volatile_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_volatile == true) return true;
		if(cv_quals.volatileCount > 1){
			cv_quals.error_for_volatile = true;
			paraphrases.push("error: duplicate 'volatile'");
			return false;
		}
		return true;
	}
	
	private boolean storage_class_specs_error(){
		storage_class_spec_scope specs = get_storage_class_spec();
		if(specs.error_found == true) return true;
		if(specs.externCount
		   + specs.staticCount
		   + specs.autoCount
		   + specs.registerCount > 1){
		
			specs.error_found = true;
			paraphrases.push("error: conflicting or duplicated storage class specifiers");
		  	return false;
		}
		return true;
	}
	
	private boolean signed_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_signed == true) return true;
		if(specs.counters.signedCount > 1){
			specs.error_for_signed = true;
			paraphrases.push("error: duplicate 'signed'");
			return false;
		}
		return true;
	}
	
	private boolean unsigned_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_unsigned == true) return true;
		if(specs.counters.unsignedCount > 1){
			specs.error_for_unsigned = true;
			paraphrases.push("error: duplicate 'unsigned'");
			return false;
		}
		return true;
	}
	
	//end error messages
	
	//AST construction
	
	Tree getChildren(CommonTree t){
		List l = t.getChildren();
		CommonTree rv = new CommonTree();
		if(l != null)
			for(Object o : l) rv.addChild((CommonTree)o);
		return rv;
	}
	
	Tree createTreeFromList(List nodes){
		CommonTree rv = new CommonTree();
		if(nodes != null)
			for(Object o : nodes) rv.addChild((CommonTree)o);
		return rv;
	}
	
	//end AST construction
	
	//Scopes
	
	//Type_Spec scope
	private class PrimitiveTypeCheck{
		int voidCount = 0,
		    charCount = 0,
		    shortCount = 0,
		    intCount = 0,
		    longCount = 0,
		    floatCount = 0,
		    doubleCount = 0,
		    boolCount = 0,
		    signedCount = 0,
		    unsignedCount = 0;
		    
		public Type checkSpecForPrimitives(boolean isConst, boolean isVolatile) throws Exception{
			int countDataTypes = voidCount + charCount   + intCount    
						       + floatCount  + doubleCount
						       + boolCount;
			
			int signs = signedCount + unsignedCount;

			//if(countDataTypes == 0) return; //error //is that possible?
			if(countDataTypes > 1) {
				throw new Exception("error: two or more data types in declaration of");
			}
			
			if(signedCount > 1 && unsignedCount > 1) {
				throw new Exception("error: 'signed' and 'unsigned' specified together for");
			}
			
			String type_name = "";
			
			if(voidCount == 1){
				if(signs != 0) {
					throw new Exception("error: 'signed' or 'unsigned' invalid for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new Exception("error: 'long' or 'short' invalid for");
				}
				type_name += "void";
			}
			else if(charCount == 1){
				if(longCount != 0 || shortCount != 0) {
					throw new Exception("error: 'long' or 'short' invalid for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "" + "char";
			}
			else if(intCount == 1){
				if(longCount > 0 && shortCount > 0){
					throw new Exception("error: 'long' and 'short' specified together for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount != 0){
					if(longCount > 2) {
						throw new Exception("error: 'long long long' invalid for");
					}
					for(int i = 0 ; i < longCount ; ++i) type_name += "long ";
				}
				else if(shortCount != 0){
					type_name += "short";
				}
				else{
					type_name += "int";
				}
			}
			else if(floatCount == 1){
				if(signs != 0) {
					throw new Exception("error: 'signed' or 'unsigned' invalid for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new Exception("error: 'long' or 'short' invalid for");
				}
				type_name += "float";
			}
			else if(doubleCount == 1){
				if(signs != 0) {
					throw new Exception("error: 'signed' or 'unsigned' invalid for");
				}
				if(shortCount > 1){
					throw new Exception("error: 'short' invalid for");
				}
				if(longCount > 1) {
					throw new Exception("error: 'long long' invalid for");
				}
				type_name += longCount == 1 ? "long " : "" + "double";
			}
			else if(boolCount == 1){
				if(signs != 0) {
					throw new Exception("error: 'signed' or 'unsigned' invalid for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new Exception("error: 'long' or 'short' invalid for");
				}
				type_name += "bool";
			}
			else if(shortCount != 0 && longCount == 0){
				type_name += unsignedCount == 1 ? "unsigned " : "" + "short";
			}
			else if(longCount != 0 && shortCount == 0){
				if(longCount > 2) {
					throw new Exception("errro: 'long long long' invalid for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount == 1) type_name += "long";
				if(longCount == 2) type_name += "long long";
			}
			else{
				throw new Exception("error: 'long' and 'short' specified together for");
			}
			
			return new PrimitiveType(type_name, isConst, isVolatile);
		}
	}
	
	private Type_Spec_scope get_Type_Spec_scope(){
		Stack type_specs = Type_Spec_stack;
		return (Type_Spec_scope)type_specs.get(type_specs.size() - 1);
	}
	
	private void Type_Spec_at_init(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		specs.error_for_signed = false;
		specs.error_for_unsigned = false;
		specs.type = new boolean[]{false,
					   false};
		specs.counters = new PrimitiveTypeCheck();
	}
	
	//End Type_Spec scope
	
	//cv_qual scope
	
	private cv_qual_scope get_cv_qual_scope(){
		Stack cv_qual_st = cv_qual_stack;
		return (cv_qual_scope)cv_qual_st.get(cv_qual_st.size() - 1);
	}
	
	
	private void cv_qual_at_init(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		cv_quals.constCount = cv_quals.volatileCount = 0;
		cv_quals.error_for_const = false;
		cv_quals.error_for_volatile = false;
	}
	//end cv_qual scope
	
	//storage_class_spec
	
	private storage_class_spec_scope get_storage_class_spec(){
		Stack storage_class_spec_st = storage_class_spec_stack;
		return (storage_class_spec_scope) storage_class_spec_st.get(storage_class_spec_st.size() - 1);
	}
	
	private void storage_class_spec_at_init(){
		storage_class_spec_scope specs = get_storage_class_spec();
		specs.error_found = false;
		specs.externCount = 0;
		specs.staticCount = 0;
		specs.autoCount = 0;
		specs.registerCount = 0;
	}
	
	//end storage_class_spec

}

translation_unit
	: external_declaration+
	;
	
/** Either a function definition or any other kind of C decl/def.
 *  The LL(*) analysis algorithm fails to deal with this due to
 *  recursion in the declarator rules.  I'm putting in a
 *  manual predicate here so that we don't backtrack over
 *  the entire function.  Further, you get a better error
 *  as errors within the function itself don't make it fail
 *  to predict that it's a function.  Weird errors previously.
 *  Remember: the goal is to avoid backtrack like the plague
 *  because it makes debugging, actions, and errors harder.
 *
 *  Note that k=1 results in a much smaller predictor for the 
 *  fixed lookahead; k=2 made a few extra thousand lines. ;)
 *  I'll have to optimize that in the future.
 */
external_declaration
options {k=1;}
	: namespace_definition
	| (/*!!!*/nested_type_id '::' declarator[null] '{') => extern_method_definition
	| (declaration_specifiers? declarator[null] '{' )=> function_definition
	| declaration
	;
	
namespace_definition
	: 'namespace' IDENTIFIER '{' external_declaration*  '}'
	;
	
extern_method_definition
	: type_specifier nested_type_id '::' declarator[null] compound_statement
	;
	
function_definition
	:	declaration_specifiers? declarator[null] compound_statement		// ANSI style only
	;
	
declaration
scope {
  boolean isTypedef;
}
@init {
  $declaration::isTypedef = false;
}
	: (struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_declaration ';'
	| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_declaration ';'
	|'typedef' declaration_specifiers? {$declaration::isTypedef=true;}
	  init_declarator_list[$declaration_specifiers.error] ';' // special case, looking for typedef	
	| declaration_specifiers init_declarator_list[$declaration_specifiers.error]? ';'
	| template_declaration
	;
	
template_declaration
	:  template_specifier declarator[null]
	;
	
template_specifier 
	: nested_template_id '<' template_parameter_list '>'
	;
	
nested_template_id
	: nested_type_id '::' template_type_id
	| template_type_id
	;
	
template_parameter_list
options{k = 2;}
	: template_specifier
	| type_specifier ','? template_parameter_list
	| type_specifier
	;
	
template_type_id
	: IDENTIFIER
	;
	
declaration_specifiers returns [Type t, String error]
scope Type_Spec;
scope cv_qual;
scope storage_class_spec;
@init{
	Type_Spec_at_init();
	cv_qual_at_init();
	storage_class_spec_at_init();
}
	:   (    storage_class_specifier
        	|   type_qualifier
        	|   type_specifier
            )+
             {
             	$t = null;
             	$error = null;
             	Type_Spec_scope type_specs = get_Type_Spec_scope();
             	cv_qual_scope cv_quals = get_cv_qual_scope();
             	boolean isConst = cv_quals.constCount != 0 ? true : false, 
             		isVolatile = cv_quals.volatileCount != 0 ? true : false;
             	//count for data types in declarations specifiers
             	int countTypes = 0;
             	for(boolean t : type_specs.type) if(t == true) ++countTypes;
             	if(countTypes > 1){	//multiple data types
             		$error = "error: two or more data types in declaration of";
             	}
             	else{
             		//declaration secifiers is for primitive type
             		if(type_specs.type[0] == true){
             			try{
             				$t = type_specs.counters.checkSpecForPrimitives(isConst, isVolatile);
             			}
             			catch(Exception ex){	
             				//erro in declaration specs for a primitive type
             				$error = ex.getMessage();
             			}
             		}
             		//other cases
             	}
             }
	;
	
function_specifier
	: 'virtual'
	| 'explicit'
	;
	
init_declarator_list [String error]
	: init_declarator [$error] (',' init_declarator[$error])*
	;
	
init_declarator [String error]
	: declarator[$error] ('=' initializer)?
	;
	
storage_class_specifier
	: 'extern'
	  {
	  	$storage_class_spec::externCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'static'
	  {
	  	$storage_class_spec::staticCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'auto'
	  {
	  	$storage_class_spec::autoCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'register'
	  {
	  	$storage_class_spec::registerCount++;
	  }
	  {storage_class_specs_error() == true}?
	;
	
type_specifier
	: 'void'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.voidCount++;
	  }
	| 'char'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.charCount++;
	  }
	| 'short'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.shortCount++;
	  }
	| 'int'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.intCount++;
	  }
	| 'long'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.longCount++;
	  }
	| 'float'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.floatCount++;
	  }
	| 'double'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.doubleCount++;
	  }
	| 'bool'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.boolCount++;
	  }
	| 'signed'		//this is the deafault, isn't it ?
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.signedCount++;
	  }
	  {signed_count_error() == true}?
	| 'unsigned'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.unsignedCount++;
	  }
	  {unsigned_count_error() == true}?
	| struct_union_or_class_specifier
	/*| enum_specifier
	| nested_type_id
	| nested_template_id*/
	;
	
nested_type_id
scope{
  ArrayList<String> types;
}
@init{
  $nested_type_id::types = new ArrayList<String>();
}
	: global_scope = '::'? type_id scope_resolution* 
	;
	
scope_resolution
	: '::' type_id
	;

struct_union_or_class_specifier
options {k=3;}
	: //(struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_declaration
	//| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_declaration
  	 struct_union_or_class IDENTIFIER
	//anonymous class ---> | struct_union_or_class  (':' 'public' nested_type_id (',' nested_type_id)*)? '{' class_declaration_list '}'
	; 

struct_union_or_class_declaration
	: struct_union_or_class IDENTIFIER (':' 'public' n1 = nested_type_id (',' n2 = nested_type_id)*)? 
  	   '{' class_declaration_list '}' init_declarator_list[null]?
	;

type_id
    : IDENTIFIER {$nested_type_id::types.add($IDENTIFIER.text);}
    //|  {}? {}? => IDENTIFIER
    ;
    
struct_union_or_class
	: 'struct'
	| 'union'
	| 'class'
	;
	
access_specifier
	: 'private'
	| 'protected'
	| 'public'
	;

class_declaration_list
	: class_content_element*
	;
	
class_content_element
	: access_specifier ':'
	| (specifier_qualifier_list declarator[null] '{') => inclass_function_definition 
	| in_class_declaration
	;
	
constructor_definition
	: className '(' parameter_type_list? ')' compound_statement
	;
	
constructor_declaration
	: className '(' parameter_type_list? ')' ';'
	;
	
destructor_definition
	: '~'className '(' ')' compound_statement
	;
	
destructor_declaration
	: '~'className '(' ')' ';'
	;

className
	: IDENTIFIER
	;
	
in_class_declaration
	: (struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_declaration ';'
	| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_declaration ';'
	|  specifier_qualifier_list class_declarator_list? ';'
	|  template_declaration
	| 'typedef' specifier_qualifier_list?
	   init_declarator_list[null] ';'
	| (constructor_definition | constructor_declaration)
	| (destructor_definition | destructor_declaration)
	;
	
inclass_function_definition
	: specifier_qualifier_list declarator[null] compound_statement
	;

specifier_qualifier_list
	: (storage_class_specifier
           |   type_qualifier
           |   function_specifier
           |   type_specifier
           |   'friend')+
	;

class_declarator_list
	: class_declarator (',' class_declarator)*
	;

class_declarator
	: declarator[null] (':' constant_expression)?
	| ':' constant_expression
	;

enum_specifier
options {k=3;}
	: 'enum' '{' enumerator_list '}'
	| 'enum' IDENTIFIER '{' enumerator_list '}'
	| 'enum' IDENTIFIER
	;

enumerator_list
	: enumerator (',' enumerator)*
	;

enumerator
	: IDENTIFIER ('=' constant_expression)?
	;

type_qualifier
	: 'const'
	  {
	    $cv_qual::constCount++;
	  }
	  {const_count_error() == true}?
	| 'volatile'
	  {
	    $cv_qual::volatileCount++;
	  }
	  {volatile_count_error() == true}?
	;

declarator[String error] returns [String declarator_name]
scope{
	String dir_decl_identifier;
	String dir_decl_error;
}
@init{
	$declarator_name = null;
	$declarator::dir_decl_error = $error;
}
	: p = pointer? direct_declarator {$declarator_name = $declarator::dir_decl_identifier;}
	//| pointer
	;

direct_declarator
	:   ( IDENTIFIER { $declarator::dir_decl_identifier = $IDENTIFIER.text; }
			 { direct_declarator_error($IDENTIFIER.text, $declarator::dir_decl_error) }?
			//{
			//if ($declaration.size()>0&& ($declaration::isTypedef)) {
			//	$Symbols::types.add($IDENTIFIER.text);
			//	System.out.println("define type "+$IDENTIFIER.text);
			//}
			//}
		|	'(' decl = declarator[$declarator::dir_decl_error] ')'
		)
        	declarator_suffix*
	;

declarator_suffix
	:'[' constant_expression ']'
    	|'[' ']'
    	|'(' parameter_type_list? ')' //const_method_specifier? pure_virt_method_specifier?
    	|'(' identifier_list? ')'									//maybe K&R style
    	//|'(' ')' const_method_specifier? pure_virt_method_specifier? == rule3 with parameter_type_list?
	;

const_method_specifier
	: 'const'
	;

pure_virt_method_specifier
	: ('=' '0')
	;

pointer
	: '*' type_qualifier+ pointer?
	| '*' pointer
	| '*'
	;

parameter_type_list
	: parameter_list (',' '...')? 
	;

parameter_list
	: params += parameter_declaration (',' params += parameter_declaration)*
	;

parameter_declaration
	: declaration_specifiers (declarators += declarator[null]| declarators += abstract_declarator)*
	;

identifier_list
	: IDENTIFIER (',' IDENTIFIER)*
	;

type_name
	: specifier_qualifier_list abstract_declarator?
	;

abstract_declarator
	: pointer direct_abstract_declarator?
	| direct_abstract_declarator
	;

direct_abstract_declarator
	:	( '(' par_decl = abstract_declarator ')' | decl_suf = abstract_declarator_suffix ) decl_suffixes += abstract_declarator_suffix*
	;

abstract_declarator_suffix
	:	'[' ']'
	|	'[' constant_expression ']'
	//|	'(' ')'		     \>
	|	'(' parameter_type_list? ')'
	;

initializer
	: assignment_expression
	| '{' initializer_list ','? '}'
	;

initializer_list
	: initializer (',' initializer)*
	;

// E x p r e s s i o n s

argument_expression_list
	:   assignment_expression (',' assignment_expression)*
	;

additive_expression
	: (multiplicative_expression) ('+' multiplicative_expression | '-' multiplicative_expression)*
	;

multiplicative_expression
	: (cast_expression) ('*' cast_expression | '/' cast_expression | '%' cast_expression)*
	;

cast_expression
	: '(' type_name ')' cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' unary_expression
	| '--' unary_expression
	| unary_operator cast_expression
	| 'sizeof' unary_expression
	| 'sizeof' '(' type_name ')'
	;

postfix_expression
	:   primary_expression
        (   '[' expression ']'
        |   '(' ')'
        |   '(' argument_expression_list ')'
        |   '.' IDENTIFIER
        |   '->' IDENTIFIER
        |   '++'
        |   '--'
        )*
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

primary_expression
	: IDENTIFIER
	| constant
	| 'this'
	| '(' expression ')'
	;

constant
 //options{greedy = true;}
    :   (ZERO | DECIMAL_LITERAL)
    |   HEX_LITERAL
    |   OCTAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;
 
expression
	: assignment_expression (',' assignment_expression)*
	;

constant_expression
	: conditional_expression
	;

assignment_expression
	: lvalue assignment_operator assignment_expression -> ^(assignment_expression lvalue assignment_expression)
	| conditional_expression
	| new_exp
	;
new_exp
	: 'new' nested_type_id ('('argument_expression_list?')')?
	;

	
lvalue
	:	unary_expression
	;

assignment_operator
	: '='
	| '*='
	| '/='
	| '%='
	| '+='
	| '-='
	| '<<='
	| '>>='
	| '&='
	| '^='
	| '|='
	;

conditional_expression
	: logical_or_expression ('?' expression ':' conditional_expression)?
	;

logical_or_expression
	: logical_and_expression ('||' logical_and_expression)*
	;

logical_and_expression
	: inclusive_or_expression ('&&' inclusive_or_expression)*
	;

inclusive_or_expression
	: exclusive_or_expression ('|' exclusive_or_expression)*
	;

exclusive_or_expression
	: and_expression ('^' and_expression)*
	;

and_expression
	: equality_expression ('&' equality_expression)*
	;
equality_expression
	: relational_expression (('=='|'!=') relational_expression)*
	;

relational_expression
	: shift_expression (('<'|'>'|'<='|'>=') shift_expression)*
	;

shift_expression
	: additive_expression (('<<'|'>>') additive_expression)*
	;

// S t a t e m e n t s

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| 'case' constant_expression ':' statement
	| 'default' ':' statement
	;

compound_statement
	: '{' (declaration | statement)* '}'				//not only at the begining
	;

statement_list
	: statement+
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: 'if' '(' expression ')' statement (options {k=1; backtrack=false;}:'else' statement)?
	| 'switch' '(' expression ')' statement
	;

iteration_statement
	: 'while' '(' expression ')' statement
	| 'do' statement 'while' '(' expression ')' ';'
	| 'for' '(' (expression_statement | simple_declaration) expression_statement expression? ')' statement
	;
	
simple_declaration 
	: type_specifier init_declarator_list[null] ';'
	;

jump_statement
	: 'goto' IDENTIFIER ';'
	| 'continue' ';'
	| 'break' ';'
	| 'return' ';'
	| 'return' expression ';'
	;

IDENTIFIER
	:	LETTER (LETTER|'0'..'9')*
	;
	
fragment
LETTER
	:	'$'
	|	'A'..'Z'
	|	'a'..'z'
	|	'_'
	;

CHARACTER_LITERAL
    :   '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
    ;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

HEX_LITERAL : '0' ('x'|'X') HexDigit+ IntegerTypeSuffix?;


ZERO 	: '0';

DECIMAL_LITERAL : ('0'  | ('1'..'9') ('0'..'9')*) IntegerTypeSuffix?;

OCTAL_LITERAL : '0' ('0'..'7')+ IntegerTypeSuffix?;

fragment
HexDigit : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
IntegerTypeSuffix
options{greedy=true;}
	:	('u' | 'U')? ('l' | 'L')
	|	('u' | 'U') ('l' | 'L')?
	;

FLOATING_POINT_LITERAL
options{greedy = true;}
    :   ('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
    |   '.' ('0'..'9')+ Exponent? FloatTypeSuffix?
    |   ('0'..'9')+ Exponent FloatTypeSuffix?
    |   ('0'..'9')+ Exponent? FloatTypeSuffix
	;

fragment
Exponent : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
FloatTypeSuffix : ('f'|'F'|'d'|'D') ;

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   OctalEscape
    ;

fragment
OctalEscape
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UnicodeEscape
    :   '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') {$channel=HIDDEN;}
    ;

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

LINE_COMMENT
    : '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;

// ignore #line info for now
LINE_COMMAND 
    : '#' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;
