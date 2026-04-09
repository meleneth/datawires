{
  for f in \
    app/views/drafts/_editor.html.haml \
    app/views/drafts/_document_editor.html.haml \
    app/views/drafts/_document_object_editor.html.haml \
    app/views/drafts/_document_scalar_editor.html.haml \
    app/views/drafts/_document_array_editor.html.haml \
    app/views/drafts/_schema_editor.html.haml \
    app/lib/editors/row.rb \
    app/lib/editors/field_cell.rb \
    app/lib/editors/commit_cell.rb \
    app/models/edit_affordance.rb \
    app/lib/documents/projection.rb \
    app/lib/documents/projection_row.rb \
    app/components/editors/document_scalar_field_component.rb \
    app/components/editors/document_scalar_field_component.html.haml \
    app/controllers/drafts_controller.rb \
    app/views/drafts/show.html.haml; do
    printf '\n===== FILE: %s =====\n\n' "$f"
    cat "$f"
    printf '\n'
  done
} | clip
