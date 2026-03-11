/**
 * @For_Static_Classes_Only
 *
 * @Current_Issues -
 * For some reason this causes AHK to parse stuff inside blocks of code that aren't being called yet and can potentially throw an error
 * that something doesn't exist (depending on your code) and would require a try statement in those "problem" areas.
 *
 * @Why_This_Exists
 * When looking at my classes, there were a lot of personalized things that didn't really fit the core of the class' purpose.
 * For example, in a Window class, you would expect some common things like an x, y, width, centerX, etc. property or methods that
 * can change the transparency or increase a window's size. Those are "common" use-cases that one might think belongs in the base class.
 * But having something like a method that switches windows by holding down a key and dragging the mouse doesn't feel like it fits in with
 * the core values, if you will, with what a Window class should be and accomplish on its own. Of course, I don't want to get rid of these
 * properties/methods as I probably use them. I decided to have separate files that will contain the properties/methods in their own class
 * and with the help of this function, add themselves to the classes that use this functionality.
 * The default approach for the original problem is just copying/pasting MyClass.DefineProp('propName', {Call: funcObj}) for each function but
 * I found that tedious and decided to come up with an automated approach as I find writing a class naturally, to be easier.
 *
 * @Setup
 * In a separate file, create a class (make sure the class name doesn't clash with another especially the one you're trying to add functionality to)
 *      that contains the properties and methods (as static) you wish to add to the target class. This is your extension file.
 * Make sure to #include the extension file in your file with the target class you wish to change.
 * From there you have two options:
 *      1. #include this file at the top of your main script before any other dependencies (#include lines) that contain the target class
 *      2. #include this file at the top of every file with the target class
 *
 * Option 1 is useful because you're only #including this file potentially once, depending on how you use AHK
 * Option 2 is useful because when you're looking at the separate class files, you can see its dependencies including this file
 *
 * Last step is to call the function AddExtension() for each class you wish to add the extensions to.
 *
 * @param {class} ext_class the name of the class with the extensions
 * @param {class?} target_class the name of the class that will inherit the extensions
 *
 * target_class will inherit any methods and properties
 */
AddExtension(target_class, ext_class) {
    AddProperty := target_class.DefineProp.Bind(target_class)           ; get class' DefineProp method
    props_to_ignore := '__Init|Prototype|__New|Call|__Item|__Get|__Set|__Call'

    for prop in ext_class.OwnProps() {                                  ; loop through classes
        if prop ~= props_to_ignore {                                    ; if a property that should be ignored
            continue                                                    ; go to next property
        }

        nested_prop := ext_class.%prop%                                 ; get nested property

        if nested_prop is Class {                                       ; if nested_prop is a nested class
            if not target_class.HasOwnProp(prop) {                      ; if nested class doesn't exist in target class
                target_class.%prop% := Class()                          ; create nested class in target class
            }

            AddExtension(target_class.%prop%, nested_prop)              ; loop through nested class
            continue                                                    ; go to next property
        }

        desc := ext_class.GetOwnPropDesc(prop)                          ; get descriptor
        AddProperty(prop, desc)                                         ; add method/property using descriptor
    }
}