# Accessibility Checklist

Before submitting a UI PR that changes a flow, you need to make sure it works with VoiceOver enabled.

## 1. Make the appropriate changes

### A) Accessibility IDs

Accessibility identifiers are **not** visible by users, and will never be spoken by VoiceOver. They are used for automated testing purposes. 

- Every view that causes an action or a change of state on tap **must** have an `accessibilityIdentifier`.
- Structuring labels such as header and footers **should** have an identifier.
- Going forward, the identifier **should** be a kebab-cased untranslated string, e.g.  `like-button`.

### B) Accessibility Labels

The accessibility label is the description of the element that will be read by VoiceOver.

- Every control and static text **must** have a meaningful `accessibilityLabel`.
- We **should not** set the label manually for text buttons and static labels.
- For image buttons, the label **should** be as minimal as possible, i.g. a verb optionally followed by a complement to disambiguate (ex: “Send”, “Draw sketch”) .
- If the label is a date, it **must** be formatted with the spelt out style.
- The label **must** start with a capital letter.
- The label **must** not end with a period, unless it’s part of the on-screen text for static labels.
- The label **must** be translated.
- The label **must not** include the type of control, as this is handled by the system automatically.

### C) Accessibility Hints

Accessibility hints are spoken after the label and provide additional context.

- Only custom controls, such as custom text fields, **must** have an `accessibilityHint`.
- Buttons **must not** have a hint. The label should be self-explaining.
- The hints **must not** describe how to use the button (ex: “double tap to enter the text”) but rather what the button does.
- The hint **must** be a start with a verb at the 3rd person without a subject that describes the action (ex: “Plays the selected song.”).
- The hints **must** start with a capital letter and end with a period.
- The hints **must** be translated.

### D) Values and Groups

- We **should** attempt to logically group labels and values (ex, for the message timestamp: label: “Timestamp”, value: “29th of February at 19h30”)
- Table view cells **should not** be accessibility elements that group elements, unless they show elements in the label/value style (ex: `value1` style), or if they contain a single action that can be performed when activating it.

### E) View Controller Considerations

- We **must** implement `accessibilityPerformEscape` in top-level view controllers. Your implementation **should** perform any cleanup required, call `dismiss(animated: true)` and return `true`. As a rule of thumb, if your view controller has a back or close button, you **should** implement this method.
- If we use a child view controller as a modal, we **must** set `accessibilityViewIsModal` to `true`.

### F) Menus

- If we use a `UIMenuController`, we **must** add the corresponding actions into the `accessibilityCustomActions ` list of the accessibility element that normally presents the menu on long press.

## 2. Perform appropriate testing

- We need to manually check that the flow can be performed with VoiceOver enabled.
