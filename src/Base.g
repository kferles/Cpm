tree grammar Base;

options{
  tokenVocab = Cpm;
  ASTLabelType=CommonTree;
}

@header{
import treeNodes4antlr.*;
}


translation_unit
	: external_declaration+
	;

external_declaration
	: namespace_definition
	| function_definition
	| declaration
	;

namespace_definition
	: ^(NAMESPACE<NamespaceToken> external_declaration*)
	;


function_definition
	: ^(METHOD<MethodToken> compound_statement)
	;

declaration
	: 'typedef'? struct_union_or_class_definition
	| 'typedef'? extern_class_definition
	| 'typedef'? enum_definition
	| 'typedef' simple_declaration
	| simple_declaration
	| using_directive
	| line_marker
	;

struct_union_or_class_definition
	: ^(STR_UN_CLASS_DEFINITION<StrUnClassDefToken> class_declaration_list? init_declarator_list?)
	;

extern_class_definition
	: ^(EXTERN_CLASS_DEFINITION<StrUnClassDefToken> class_declaration_list? init_declarator_list?)
	;

class_declaration_list
	: class_content_element*
	;

class_content_element
	: access_specifier
	| function_definition
	| in_class_declaration
	;

in_class_declaration
	: constructor
	| destructor
	| declaration
	;

access_specifier
	: 'private'
	| 'protected'
	| 'public'
	;

enum_definition
	: ^(ENUM_DEFINITION<EnumDefinitionToken> enumerator_list init_declarator_list?)
	;
	
enumerator_list
	: enumerator+
	;

enumerator
	: IDENTIFIER ('=' constant_expression)?
	;

simple_declaration
	: FWD_DECLARATION<FwdDeclarationToken>
	| ^(FWD_DECLARATION<FwdDeclarationToken> init_declarator_list)
	| init_declarator_list
	;

init_declarator_list
   	: ^(DECLARATION_LIST init_declarator+)
   	;

init_declarator
   : ^(DECLARATION<DeclarationToken> declarator)
       { 
	  DeclarationToken node = (DeclarationToken) $DECLARATION.getToken();
	  String id = $declarator.id;
	  System.out.println(node.getDeclType().toString(id));
       }
     | ^(DECLARATION<DeclarationToken> ^('=' declarator initializer))
     | ^(DECLARATION<DeclarationToken> argument_expression_list)
   ;

using_directive
	: USING_DIRECTIVE<UsingDirectiveToken>
	;
	
nested_name_id
	: ^('::' id scope_resolution*)
	| ^(id scope_resolution*)
	;

scope_resolution
	: '::' id
	;

id
  : template_id
  | name_id
  ;

name_id
  : IDENTIFIER	
  ;

template_id
	: IDENTIFIER '<' template_argument_list '>'
	;

template_argument_list
	: template_argument ',' template_argument_list
	| template_argument
	;

template_argument
	: type_name
	;

declarator returns [String id]
	: IDENTIFIER {$id = $IDENTIFIER.text;}
	| nested_identifier
	;

type_name
	: TYPE_NAME<TypeNameToken>
	;

initializer
	: assignment_expression
	| initializer_list
	;

initializer_list
	: ^(INITIALIZER_LIST initializer+)
	;
	
// In Class Declarations


constructor
	: CONSTRUCTOR<ConstructorToken>
	| ^(CONSTRUCTOR<ConstructorToken> ctor_initializer? compound_statement)
	;
	
destructor
	: DESTRUCTOR<DestructorToken>
	| ^(DESTRUCTOR<DestructorToken> compound_statement)
	;
	

ctor_initializer
	: mem_initializer_list
	;

mem_initializer_list
	: mem_initializer
	| ^(',' mem_initializer mem_initializer_list)
	;

mem_initializer
	: mem_initializer_id '(' expression* ')'
	;

mem_initializer_id
	: nested_identifier
	| IDENTIFIER
	;


// E x p r e s s i o n s

expression
	: assignment_expression (',' assignment_expression)*
	;

assignment_expression
	: ^(assignment_operator logical_or_expression assignment_expression)
	| conditional_expression
	;

constant_expression
	: conditional_expression
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
	: ^('?' logical_or_expression ^(':' expression assignment_expression))
	| logical_or_expression
	;

logical_or_expression
	: logical_and_expression
	| ^('||' logical_and_expression logical_and_expression)
	;

logical_and_expression
	: inclusive_or_expression
	| ^('&&' inclusive_or_expression inclusive_or_expression)
	;

inclusive_or_expression
	: exclusive_or_expression
	| ^('|' exclusive_or_expression exclusive_or_expression)
	;

exclusive_or_expression
	: and_expression
	| ^('^' and_expression and_expression)
	;

and_expression
	: equality_expression
	| ^('&' equality_expression equality_expression)
	;

equality_expression
	: relational_expression
	| ^(('=='|'!=') relational_expression relational_expression)
	;
	
relational_expression
	: shift_expression
	| ^(('<'|'>'|'<='|'>=') shift_expression shift_expression)
	;

shift_expression
	: additive_expression
	| ^(('<<' | '>>') additive_expression additive_expression)
	;

additive_expression
	: multiplicative_expression
	| ^(('+' | '-') multiplicative_expression multiplicative_expression)
	;

multiplicative_expression
	: cast_expression
	| ^(('*' | '%' | '/') cast_expression cast_expression)
	;

cast_expression
	: type_name cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' cast_expression
	| '--' cast_expression
	| unary_operator cast_expression
	| 'sizeof' type_name
	| 'sizeof' unary_expression
	| new_expression
	| delete_expression
	;

postfix_expression
	: primary_expression
	(
	  ^(INDEX postfix_expression expression)
	| ^(CALL postfix_expression argument_expression_list?)
	| ^(OBJ_ACCESS postfix_expression nested_name_id)
	| ^(PTR_ACCESS postfix_expression nested_name_id)
	| ^(INCR_POSTFIX postfix_expression)
	| ^(DECR_POSTFIX postfix_expression)
	)
	;

argument_expression_list
	: assignment_expression (',' assignment_expression)*
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
	: constant
	| 'this'
	| id_expression
	| '(' expression ')'
	;

id_expression
	: ^(ID_EXPRESSION<IdExpressionToken> '::' id_expression_tail?)
	| ^(ID_EXPRESSION<IdExpressionToken> id_expression_tail?)
	;

id_expression_tail
	: ^('::' IDENTIFIER id_expression_tail)
	| IDENTIFIER
	;

constant
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;

new_expression
	: ^('new'new_type_id ^(NEW_INITIALIZER new_initializer?))
	| ^('new' type_name ^(NEW_INITIALIZER new_initializer?))
	;

new_type_id
	: NEW_TYPE_ID<NewTypeIdToken>
	;

new_initializer
	: '(' argument_expression_list? ')'
	;

delete_expression
	: 'delete' cast_expression
	| 'delete' '[' ']' cast_expression
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
	: ^(CASE_STMT constant_expression ^(CASE_SLCT statement))
	| ^(DEFAULT_STMT ^(CASE_SLCT statement))
	;

compound_statement
	: '{' ( declaration
	      | statement)* '}'	
	;

expression_statement
	: ';'
	| expression
	;

selection_statement
	: ^(IF_STMT expression statement)
	| ^(IF_ELSE_STMT expression statement ^(ELSE_PRT statement))
	| ^(SWITCH_STMT expression statement)
	;

iteration_statement
	: ^(WHILE_COND expression ^(WHILE_BODY statement))
	| ^(DO_WHILE_STMT ^(DO_WHILE_BODY statement) ^(WHILE_COND expression))
	| ^(FOR_STMT for_init_statement expression_statement expression? ^(FOR_BODY statement))
	;

for_init_statement
	: simple_declaration
	| expression_statement
	;

jump_statement
	: 'continue'
	| 'break'
	| ^(RETURN_EXP expression)
	| RETURN_EXP
	;

//C+- aux rules (different rules to adjust C's syntax)

nested_identifier
	: ^(NESTED_IDENTIFIER<NestedIdentifierToken> '::' IDENTIFIER ^('::' nested_identifier_tail))
	| ^(NESTED_IDENTIFIER<NestedIdentifierToken> IDENTIFIER '::' nested_identifier_tail)
	;

nested_identifier_tail
	: ^(IDENTIFIER '::' nested_identifier_tail)
	| IDENTIFIER
	;

//Preprocessor

line_marker
	:  LINE_MARKER_EXIT<LineMarkerToken>
	|  LINE_MARKER_ENTER<EntryLineMarkerToken>
	;
